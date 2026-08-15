-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Client Portfolio & Revenue Analytics
-- Country: PHILIPPINES | Currency: PHP
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- CLIENTS: 58 rows — Enterprise client profiles (US, UK, AU, SG Fortune 500 companies)
-- CONTRACTS: 124 rows — Active contracts with terms, value, renewal dates
-- REVENUE_TRANSACTIONS: 340,000 rows — Monthly revenue recognition by client, service line, site
-- DELIVERY_METRICS: 580,000 rows — Monthly delivery KPIs per client (utilization, quality, timeliness)
-- CLIENT_SURVEYS: 2,400 rows — Quarterly client satisfaction surveys and NPS
-- MARKET_INTELLIGENCE: 500 rows — Industry reports on BPO market size, growth, and competition
