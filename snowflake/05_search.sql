-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.MARKET_INTEL_SEARCH
  ON REPORT_CONTENT
  ATTRIBUTES VERTICAL, REGION, PUBLISHER
  WAREHOUSE = PORTFOLIO_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.MARKET_INTELLIGENCE
);
