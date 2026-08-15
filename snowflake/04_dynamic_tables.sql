-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA CURATED;

-- CLIENT_HEALTH_SCORE: Composite health score per client (delivery + satisfaction + financial)
-- Source: CLIENTS, DELIVERY_METRICS, CLIENT_SURVEYS, REVENUE_TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.CLIENT_HEALTH_SCORE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PORTFOLIO_WH
AS
SELECT * FROM RAW.CLIENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- REVENUE_360: Revenue by client, vertical, service line with growth rates
-- Source: CLIENTS, CONTRACTS, REVENUE_TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.REVENUE_360
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PORTFOLIO_WH
AS
SELECT * FROM RAW.CLIENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- RENEWAL_PIPELINE: Contracts approaching renewal with health context
-- Source: CONTRACTS, CLIENT_HEALTH_SCORE
CREATE OR REPLACE DYNAMIC TABLE CURATED.RENEWAL_PIPELINE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PORTFOLIO_WH
AS
SELECT * FROM RAW.CONTRACTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PORTFOLIO_CONCENTRATION: Revenue concentration risk analysis (top-client dependency)
-- Source: CLIENTS, REVENUE_TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PORTFOLIO_CONCENTRATION
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PORTFOLIO_WH
AS
SELECT * FROM RAW.CLIENTS;
-- TODO: Replace with actual join/aggregation logic per demo

