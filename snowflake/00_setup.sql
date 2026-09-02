-- Generated from generator/demo_specs/aws-philippines-bpo-client-portfolio.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-philippines-bpo-client-portfolio
-- This is the schema that is actually deployed for PH_BPO_CLIENT_PORTFOLIO.

-- PH_BPO_CLIENT_PORTFOLIO  (Client Portfolio & Revenue Analytics)
-- generated from generator/demo_specs/aws-philippines-bpo-client-portfolio.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS PH_BPO_CLIENT_PORTFOLIO;
CREATE SCHEMA IF NOT EXISTS PH_BPO_CLIENT_PORTFOLIO.RAW;
CREATE SCHEMA IF NOT EXISTS PH_BPO_CLIENT_PORTFOLIO.CURATED;
CREATE SCHEMA IF NOT EXISTS PH_BPO_CLIENT_PORTFOLIO.APP;
USE DATABASE PH_BPO_CLIENT_PORTFOLIO;

-- 5 real regions; entity names carry their region so the two always agree
