-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): CEIC ASEAN Macro
--   Real data: https://app.snowflake.com/marketplace/listing/GZTSZRC7HPI
--   Using mock table: MARKET_INTELLIGENCE
CREATE TABLE IF NOT EXISTS RAW.MARKET_INTELLIGENCE (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

