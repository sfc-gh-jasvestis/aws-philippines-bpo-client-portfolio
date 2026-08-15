-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_REFRESH_HEALTH_SCORES
  WAREHOUSE = PORTFOLIO_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  COMMENT = 'Refresh client health scores daily'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_EXPORT_ICEBERG
  WAREHOUSE = PORTFOLIO_WH
  AFTER APP.TASK_REFRESH_HEALTH_SCORES
  COMMENT = 'Export portfolio data to Iceberg format for cross-platform access'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_GENERATE_SUMMARIES
  WAREHOUSE = PORTFOLIO_WH
  AFTER APP.TASK_EXPORT_ICEBERG
  COMMENT = 'Generate AI account summaries for account directors'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_GENERATE_SUMMARIES RESUME;
ALTER TASK APP.TASK_EXPORT_ICEBERG RESUME;
ALTER TASK APP.TASK_REFRESH_HEALTH_SCORES RESUME;
