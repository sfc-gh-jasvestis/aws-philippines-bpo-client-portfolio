-- ============================================================================
-- Client Portfolio & Revenue Analytics
-- Philippine BPOs manage multi-billion peso client portfolios — Snowflake builds real-time client health scores with Dynamic Tables, exports to Iceberg for cross-platform reporting, and enables revenue intelligence at scale.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS CLIENT_PORTFOLIO;
CREATE WAREHOUSE IF NOT EXISTS PORTFOLIO_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE CLIENT_PORTFOLIO;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE PORTFOLIO_WH;
