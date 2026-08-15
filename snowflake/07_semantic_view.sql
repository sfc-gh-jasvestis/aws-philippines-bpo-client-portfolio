-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.CLIENT_PORTFOLIO_ANALYTICS
  COMMENT = 'Client revenue, health, renewal, and portfolio concentration analytics'
AS
  TABLES (
    CURATED.CLIENT_HEALTH_SCORE AS client_health_score,CURATED.REVENUE_360 AS revenue_360,CURATED.RENEWAL_PIPELINE AS renewal_pipeline,CURATED.PORTFOLIO_CONCENTRATION AS portfolio_concentration
  );
