-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-interaction alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_INTERACTIONS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic escalation knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.ESCALATION_DOCS AS
WITH types AS (
  SELECT DISTINCT r.ESCALATION_TYPE, a.CATEGORY
  FROM RAW.ACCOUNT_DAILY r JOIN RAW.ACCOUNTS a ON a.ID = r.ENTITY_ID
  WHERE r.BREACH_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ESCALATION_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ESCALATION_TYPE,
  CATEGORY || ' - ' || ESCALATION_TYPE || ' escalation handling' AS TITLE,
  'Synthetic demo SOP. Client vertical: ' || CATEGORY || '. Escalation type: ' || ESCALATION_TYPE || '. '
  || 'Step 1: open an escalation case, link the contact record and assign a team lead on the account within the first hour. '
  || 'Step 2: ' || CASE
       WHEN ESCALATION_TYPE = 'Disputed transaction backlog' THEN 'sort the open disputes by SLA clock, move senior agents onto the oldest cases, and send the client a backlog status update before the end of the shift.'
       WHEN ESCALATION_TYPE = 'Script compliance deviation' THEN 'pull the call recordings flagged by QA, re-brief the agents on the approved script, and schedule a calibration audit within 48 hours.'
       WHEN ESCALATION_TYPE = 'Callback not completed' THEN 'list the missed callbacks, schedule them in the next available slot, and confirm each callback with the end customer.'
       WHEN ESCALATION_TYPE = 'Billing dispute' THEN 'confirm the disputed amount against the client billing system, apply the client adjustment rules, and route unresolved cases to the client billing team.'
       WHEN ESCALATION_TYPE = 'Repeat outage complaint' THEN 'link the repeat contacts to the open network ticket, give agents the latest client status note, and flag the cluster to the client operations desk.'
       WHEN ESCALATION_TYPE = 'Booking change backlog' THEN 'sort pending booking changes by travel date, add overflow agents for the next shift, and confirm changes due within 72 hours first.'
       WHEN ESCALATION_TYPE = 'Refund delay complaint' THEN 'check the refund status in the client system, give the end customer the expected date, and escalate refunds past the client deadline to the client finance contact.'
       WHEN ESCALATION_TYPE = 'Delivery status backlog' THEN 'refresh the delivery status from the client tracking feed, answer the oldest queries first, and send repeat queries to the client logistics contact.'
       WHEN ESCALATION_TYPE = 'Ticket reopened' THEN 'review why the ticket was reopened, assign it to a tier 2 agent, and add the fix to the knowledge base before closing.'
       WHEN ESCALATION_TYPE = 'Knowledge base gap' THEN 'draft the missing knowledge article with the client product team, publish it to the agent desktop, and brief the shift.'
       ELSE 'review the escalation against the account profile and raise it with the account director if unexplained.'
     END
  || ' Step 3: if the repeat contact rate for the account exceeds 14% or the average handle time exceeds 10 minutes after triage, keep the case open and request an account quality review. '
  || 'Step 4: record the resolution; if the escalation breached the SLA or triggered a service credit, notify the client account manager and log it for the monthly service review.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ESCALATION_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ESCALATION_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ESCALATION_TYPE, CONTENT FROM SEARCH.ESCALATION_DOCS);

-- ---------- Repeat contact rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.REPEAT_CONTACT_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, REPEAT_CONTACT_PCT::FLOAT AS REPEAT_CONTACT
FROM RAW.ACCOUNT_DAILY;
CREATE OR REPLACE VIEW ML.REPEAT_CONTACT_TRAIN AS
SELECT * FROM ML.REPEAT_CONTACT_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.REPEAT_CONTACT_SERIES);
CREATE OR REPLACE VIEW ML.REPEAT_CONTACT_DETECT AS
SELECT * FROM ML.REPEAT_CONTACT_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.REPEAT_CONTACT_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.REPEAT_CONTACT_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.REPEAT_CONTACT_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'REPEAT_CONTACT',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.REPEAT_CONTACT_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS REPEAT_CONTACT, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.REPEAT_CONTACT_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.REPEAT_CONTACT_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'REPEAT_CONTACT'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.PORTFOLIO_ANALYTICS
  TABLES (
    accounts AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'clients', 'client accounts', 'programmes')
      COMMENT = 'One row per client account (delivery site city and client vertical), 90-day totals',
    risk AS ML.BREACH_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day SLA breach probability per account',
    escalations AS CURATED.ESCALATION_SUMMARY PRIMARY KEY (ESCALATION_TYPE)
      COMMENT = 'Escalations, SLA breaches and service credits by escalation type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Portfolio-wide totals per day'
  )
  RELATIONSHIPS (risk_account AS risk (ENTITY_ID) REFERENCES accounts)
  FACTS (
    accounts.escalations_f AS ESCALATION_COUNT,
    accounts.breaches_f AS BREACH_COUNT,
    accounts.credits_f AS SERVICE_CREDIT_COUNT,
    accounts.contacts_f AS CONTACT_COUNT,
    accounts.revenue_f AS REVENUE_PHP,
    accounts.audit_due_f AS QA_AUDIT_DUE,
    accounts.audit_done_f AS QA_AUDIT_DONE,
    risk.breach_prob_f AS BREACH_PROB_7D,
    escalations.type_escalations_f AS ESCALATION_COUNT,
    escalations.type_breaches_f AS BREACH_COUNT,
    escalations.type_credits_f AS SERVICE_CREDIT_COUNT,
    escalations.type_revenue_f AS EXPOSED_REVENUE_PHP,
    daily.day_escalations_f AS ESCALATION_COUNT,
    daily.day_breaches_f AS BREACH_COUNT,
    daily.day_revenue_f AS REVENUE_PHP
  )
  DIMENSIONS (
    accounts.account_id AS ENTITY_ID WITH SYNONYMS = ('account', 'client', 'entity', 'programme'),
    accounts.account_name AS ENTITY_NAME,
    accounts.city AS REGION WITH SYNONYMS = ('city', 'region', 'location')
      COMMENT = 'Philippine delivery site city that serves the account',
    accounts.category AS CATEGORY WITH SYNONYMS = ('client vertical', 'vertical'),
    accounts.risk_tier AS RISK_TIER COMMENT = 'Account service risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    escalations.escalation_type AS ESCALATION_TYPE WITH SYNONYMS = ('escalation', 'escalation category', 'escalation reason'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    accounts.account_count AS COUNT(accounts.account_id) WITH SYNONYMS = ('number of accounts', 'number of entities', 'how many accounts'),
    accounts.clean_contact_rate_pct AS 100 * (SUM(accounts.contacts_f) - SUM(accounts.escalations_f)) / NULLIF(SUM(accounts.contacts_f), 0)
      WITH SYNONYMS = ('clean contact rate', 'contacts without escalation')
      COMMENT = 'Contacts without an escalation / contacts handled',
    accounts.escalation_breach_pct AS 100 * SUM(accounts.breaches_f) / NULLIF(SUM(accounts.escalations_f), 0)
      COMMENT = 'SLA breaches / escalations raised',
    accounts.escalations_raised AS SUM(accounts.escalations_f) WITH SYNONYMS = ('escalations', 'complaints'),
    accounts.sla_breaches AS SUM(accounts.breaches_f) WITH SYNONYMS = ('SLA breaches', 'breached'),
    accounts.service_credits AS SUM(accounts.credits_f) WITH SYNONYMS = ('service credits', 'SLA credits', 'penalty credits'),
    accounts.contacts_handled AS SUM(accounts.contacts_f) WITH SYNONYMS = ('contacts', 'contact volume'),
    accounts.total_revenue_php AS SUM(accounts.revenue_f) WITH SYNONYMS = ('billed revenue', 'revenue', 'revenue in PHP'),
    accounts.qa_audit_compliance_pct AS 100 * SUM(accounts.audit_done_f) / NULLIF(SUM(accounts.audit_due_f), 0)
      COMMENT = 'QA audits completed / QA audits due',
    risk.avg_breach_prob AS AVG(risk.breach_prob_f),
    escalations.type_escalations AS SUM(escalations.type_escalations_f),
    escalations.type_breaches AS SUM(escalations.type_breaches_f),
    escalations.type_credits AS SUM(escalations.type_credits_f),
    escalations.type_breach_share_pct AS 100 * SUM(escalations.type_breaches_f) / NULLIF(SUM(escalations.type_escalations_f), 0),
    daily.daily_escalations AS SUM(daily.day_escalations_f),
    daily.daily_breaches AS SUM(daily.day_breaches_f),
    daily.daily_revenue_php AS SUM(daily.day_revenue_f)
  )
  COMMENT = 'Synthetic Philippine BPO client portfolio analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.PORTFOLIO_AGENT
  COMMENT = 'Client portfolio operations assistant over a synthetic Philippine BPO provider'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give account IDs and numbers with units (PHP, %)."
  orchestration: "Use portfolio_analyst for contacts, billed revenue, escalations, SLA breaches, service credits, clean contact rate, QA audit compliance, accounts, delivery site cities, client verticals, escalation types and SLA breach risk. Use sop_search for escalation handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: portfolio_analyst
      description: "Contacts handled, billed revenue in PHP, escalations, SLA breaches, service credits, clean contact rate, QA audit compliance, escalation types and SLA breach risk scores by account, delivery site city and client vertical"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic escalation handling SOPs by client vertical and escalation type"
tool_resources:
  portfolio_analyst:
    semantic_view: __DEMO_DB__.APP.PORTFOLIO_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.ESCALATION_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-interaction alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), ACCOUNT_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_PHP FLOAT, HANDLE_MINUTES FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION PH_BPO_CLIENT_PORTFOLIO_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (ACCOUNT_ID, EVENT_TS, AMOUNT_PHP, HANDLE_MINUTES, SOP_HINT)
    SELECT p.ACCOUNT_ID, p.EVENT_TS, p.AMOUNT_PHP, p.HANDLE_MINUTES,
           'Check ' || r.CATEGORY || ' escalation SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_INTERACTIONS p
    JOIN RAW.ACCOUNTS r ON r.ID = p.ACCOUNT_ID
    LEFT JOIN ML.BREACH_RISK_SCORES s ON s.ENTITY_ID = p.ACCOUNT_ID
    WHERE p.STATUS = 'ESCALATED'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.ACCOUNT_ID = p.ACCOUNT_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('PH_BPO_CLIENT_PORTFOLIO_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Escalation alert',
      'New live escalations logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_INTERACTION_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_INTERACTIONS p
    WHERE p.STATUS = 'ESCALATED'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.ACCOUNT_ID = p.ACCOUNT_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.ESCALATION_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.BREACH_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.BREACH_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.BREACH_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'ACCOUNT_TENURE_YEARS', ACCOUNT_TENURE_YEARS,
             'REPEAT_CONTACT_PCT', REPEAT_CONTACT_PCT, 'AVG_HANDLE_MIN', AVG_HANDLE_MIN,
             'REPEAT_CONTACT_7D', REPEAT_CONTACT_7D, 'BREACHES_30D', BREACHES_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:BREACH::FLOAT, 4) AS BREACH_PROB_7D,
         CASE WHEN PRED:probability:BREACH::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:BREACH::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
