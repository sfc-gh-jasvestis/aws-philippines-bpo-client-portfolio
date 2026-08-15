-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Client Portfolio & Revenue Analytics
-- ============================================================================
USE DATABASE CLIENT_PORTFOLIO;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.PORTFOLIO_INTELLIGENCE_AGENT
  COMMENT = 'Client Portfolio & Revenue Analytics AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'CLIENT_PORTFOLIO.APP.CLIENT_PORTFOLIO_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'CLIENT_PORTFOLIO.SEARCH.MARKET_INTEL_SEARCH', TOOL_DESCRIPTION => 'Search documents for BPO & IT Services information')
  )
  SYSTEM_PROMPT = 'You are the Portfolio Intelligence Agent for a Philippine BPO with 58 enterprise clients and ₱4.8B annual revenue across IT services, finance, healthcare, and telecom verticals.';
