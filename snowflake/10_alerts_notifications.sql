-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_philippines_bpo_client_portfolio_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: CHURN_RISK_ALERT
CREATE OR REPLACE ALERT APP.CHURN_RISK_ALERT
  WAREHOUSE = PORTFOLIO_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'At-risk client approaching contract renewal'
IF (EXISTS (
  SELECT 1 FROM CURATED.CLIENT_HEALTH_SCORE
  WHERE 1=1 -- Condition: HEALTH_SCORE < 60 AND CONTRACT_RENEWAL_WITHIN_90D = TRUE
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_bpo_client_portfolio_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Client Portfolio & Revenue Analytics: At-risk client approaching contract renewal',
    'At-risk client approaching contract renewal'
  );

ALTER ALERT APP.CHURN_RISK_ALERT RESUME;

-- Alert: CONCENTRATION_ALERT
CREATE OR REPLACE ALERT APP.CONCENTRATION_ALERT
  WAREHOUSE = PORTFOLIO_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Portfolio concentration risk exceeds threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.CLIENT_HEALTH_SCORE
  WHERE 1=1 -- Condition: TOP_CLIENT_REVENUE_PCT > 15%
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_bpo_client_portfolio_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Client Portfolio & Revenue Analytics: Portfolio concentration risk exceeds threshold',
    'Portfolio concentration risk exceeds threshold'
  );

ALTER ALERT APP.CONCENTRATION_ALERT RESUME;

