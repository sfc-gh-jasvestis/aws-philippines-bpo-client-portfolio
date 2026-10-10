-- Synthetic account-day observations for a fictional Philippine BPO provider.
-- An account is one fictional enterprise client programme served from one
-- delivery site city in one client vertical. Nothing is seeded as a prediction.
-- Randomness is HASH-seeded, so every rebuild is reproducible: per-account SLA
-- breach propensity, quality drift between QA calibration audits, missed audits,
-- vertical-weighted escalation types, escalations closed within SLA, and two
-- site-wide connectivity outages.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.ACCOUNTS AS
WITH accounts AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS ACCOUNT_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT ACCOUNT_INDEX,
         MOD(ABS(HASH(ACCOUNT_INDEX, 'phbpo-tenure')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(ACCOUNT_INDEX, 'phbpo-breach-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(ACCOUNT_INDEX, 'phbpo-audit-cycle')), 1000000) / 1e6 AS U_AUDIT,
         MOD(ABS(HASH(ACCOUNT_INDEX, 'phbpo-audit-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(ACCOUNT_INDEX, 'phbpo-tier')), 1000000) / 1e6 AS U_TIER
  FROM accounts
)
SELECT 'ACC-' || LPAD(ACCOUNT_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic client account ' || LPAD(ACCOUNT_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and vertical is present.
       CASE MOD(ACCOUNT_INDEX, 5) WHEN 0 THEN 'Quezon City' WHEN 1 THEN 'Cebu City'
            WHEN 2 THEN 'Davao City' WHEN 3 THEN 'Iloilo City' ELSE 'Bacolod' END AS REGION,
       CASE MOD(ACCOUNT_INDEX, 8) WHEN 0 THEN 'Financial services' WHEN 1 THEN 'Financial services'
            WHEN 2 THEN 'Telecommunications' WHEN 3 THEN 'Telecommunications'
            WHEN 4 THEN 'Retail and e-commerce' WHEN 5 THEN 'Travel and hospitality'
            WHEN 6 THEN 'Technology support' ELSE 'Retail and e-commerce' END AS CATEGORY,
       ACCOUNT_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.3 + U_AGE * 7.7, 1) AS ACCOUNT_TENURE_YEARS,
       -- Base daily probability of an SLA breach 0.4%-3%; ~15% of accounts are
       -- chronically weak (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_BREACH_RATE,
       7 * (1 + FLOOR(U_AUDIT * 3)) AS QA_AUDIT_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS QA_AUDIT_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.ACCOUNT_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two site-wide connectivity outages; every account at the site raises an
  -- escalation that is closed within SLA once failover completes.
  SELECT * FROM VALUES (33, 'Davao City'), (61, 'Iloilo City') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.ACCOUNT_INDEX, s.CATEGORY, s.REGION, s.ACCOUNT_TENURE_YEARS,
         s.BASE_BREACH_RATE, s.QA_AUDIT_INTERVAL_DAYS, s.QA_AUDIT_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + s.ACCOUNT_INDEX * 3, s.QA_AUDIT_INTERVAL_DAYS) AS DAYS_SINCE_AUDIT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-breach')), 1000000) / 1e6 AS U_BREACH,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-escalate')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-close')), 1000000) / 1e6 AS U_RESOLVE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-esc-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-audit-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-contacts')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'phbpo-credit')), 1000000) / 1e6 AS U_LATE,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.ACCOUNTS s CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), audit AS (
  SELECT *,
         IFF(DAYS_SINCE_AUDIT = 0, 1, 0) AS QA_AUDIT_DUE,
         IFF(DAYS_SINCE_AUDIT = 0 AND U_DONE < QA_AUDIT_COMPLETION_PROB, 1, 0) AS QA_AUDIT_DONE,
         -- Quality drift (agents drifting from the calibrated standard) rises
         -- between QA calibration audits; weak audit discipline carries it over.
         DAYS_SINCE_AUDIT / QA_AUDIT_INTERVAL_DAYS + (1 - QA_AUDIT_COMPLETION_PROB) AS DRIFT
  FROM base
), breaches AS (
  SELECT *,
         CASE WHEN U_BREACH < LEAST(0.5, BASE_BREACH_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + ACCOUNT_TENURE_YEARS))) / 4 THEN 2
              WHEN U_BREACH < LEAST(0.5, BASE_BREACH_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + ACCOUNT_TENURE_YEARS))) THEN 1
              ELSE 0 END AS BREACH_RISK_COUNT
  FROM audit
), escalations AS (
  SELECT *,
         -- About 85% of at-risk escalations miss the SLA; the rest are caught
         -- by the account team before the SLA clock runs out.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, BREACH_RISK_COUNT, 0)) AS BREACH_COUNT,
         -- Escalations closed within SLA: higher for high-volume verticals.
         IFF(CITY_EVENT, 1, IFF(U_RESOLVE < CASE CATEGORY WHEN 'Telecommunications' THEN 0.19
                                                         WHEN 'Retail and e-commerce' THEN 0.13
                                                         WHEN 'Technology support' THEN 0.15 ELSE 0.09 END, 1, 0)) AS RESOLVED_COUNT
  FROM breaches
), measured AS (
  SELECT *,
         BREACH_COUNT + RESOLVED_COUNT AS ESCALATION_COUNT,
         ROUND(CASE CATEGORY WHEN 'Telecommunications' THEN 1700 WHEN 'Retail and e-commerce' THEN 1150
                             WHEN 'Technology support' THEN 380 WHEN 'Travel and hospitality' THEN 620 ELSE 880 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.3 * BREACH_RISK_COUNT)) AS CONTACT_COUNT,
         CASE CATEGORY WHEN 'Telecommunications' THEN 118 WHEN 'Retail and e-commerce' THEN 104
                       WHEN 'Technology support' THEN 365 WHEN 'Travel and hospitality' THEN 158 ELSE 212 END
           * (0.85 + 0.3 * U_NOISE) AS AVG_CONTACT_PHP
  FROM escalations
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       CONTACT_COUNT,
       ROUND(CONTACT_COUNT * AVG_CONTACT_PHP, 0) AS REVENUE_PHP,
       ESCALATION_COUNT, BREACH_COUNT,
       IFF(BREACH_COUNT > 0 AND U_LATE < 0.55, 1, 0) AS SERVICE_CREDIT,
       CASE WHEN ESCALATION_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Site connectivity outage'
            WHEN CATEGORY = 'Financial services' THEN IFF(U_TYPE < 0.45, 'Disputed transaction backlog', IFF(U_TYPE < 0.8, 'Script compliance deviation', 'Callback not completed'))
            WHEN CATEGORY = 'Telecommunications' THEN IFF(U_TYPE < 0.5, 'Billing dispute', IFF(U_TYPE < 0.8, 'Repeat outage complaint', 'Callback not completed'))
            WHEN CATEGORY = 'Travel and hospitality' THEN IFF(U_TYPE < 0.55, 'Booking change backlog', 'Refund delay complaint')
            WHEN CATEGORY = 'Technology support' THEN IFF(U_TYPE < 0.45, 'Ticket reopened', IFF(U_TYPE < 0.8, 'Knowledge base gap', 'Callback not completed'))
            ELSE IFF(U_TYPE < 0.5, 'Refund delay complaint', IFF(U_TYPE < 0.75, 'Delivery status backlog', 'Billing dispute')) END AS ESCALATION_TYPE,
       QA_AUDIT_DUE, QA_AUDIT_DONE,
       ROUND(6.0 + 4.0 * DRIFT + 5.0 * BREACH_RISK_COUNT + U_NOISE * 1.6, 2) AS REPEAT_CONTACT_PCT,
       ROUND(5.5 + 2.2 * DRIFT + 2.6 * BREACH_RISK_COUNT + U_NOISE * 1.1, 1) AS AVG_HANDLE_MIN,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Agent certification coverage per account (snapshot): agents required to hold
-- the account's certification, agents certified, and agents in training.
CREATE TABLE RAW.AGENT_CERTIFICATIONS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Financial services' THEN 'Payments data handling certification'
                     WHEN 'Telecommunications' THEN 'Network troubleshooting certification'
                     WHEN 'Travel and hospitality' THEN 'Reservation system certification'
                     WHEN 'Technology support' THEN 'Tier 2 technical certification'
                     ELSE 'Returns and refunds certification' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'phbpo-cert-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'phbpo-cert-held')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'phbpo-cert-held')), 5) < 1 + MOD(ABS(HASH(ID, 'phbpo-cert-req')), 4),
           MOD(ABS(HASH(ID, 'phbpo-cert-training')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.ACCOUNTS;
