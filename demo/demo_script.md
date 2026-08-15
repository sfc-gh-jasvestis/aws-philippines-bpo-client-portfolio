# Demo Script: Client Portfolio & Revenue Analytics
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake consolidates client revenue, delivery, and satisfaction data into Dynamic Table health scores, exports to Iceberg for cross-platform access, and provides Cortex Agent-powered portfolio intelligence for account managers"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Isabella Sofia Ayala-Zobel** | Chief Revenue Officer | React App (SPCS) | Revenue growth, client retention, upsell pipeline, margin trends, portfolio concentration risk |
| **Antonio Miguel Sy** | Account Director | Amazon QuickSight | Individual client P&L, contract renewals, scope expansion, delivery health |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | CLIENTS (58), CONTRACTS (124), REVENUE_TRANSACTIONS (340000), DELIVERY_METRICS (580000), CLIENT_SURVEYS (2400), MARKET_INTELLIGENCE (500) |
| **CURATED** | 4 Dynamic Tables | CLIENT_HEALTH_SCORE, REVENUE_360, RENEWAL_PIPELINE, PORTFOLIO_CONCENTRATION |
| **ML** | ML.CLASSIFICATION + ML.FORECAST | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 500 documents indexed |
| **Agent** | PORTFOLIO_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

A leading Philippine BPO manages a ₱4.8 billion client portfolio across 58 enterprise clients spanning finance, healthcare, telecom, retail, and technology. Seven clients are deteriorating — three have renewals in 90 days. But client health data lives in 6 disconnected systems. Snowflake unifies delivery, satisfaction, and financial data into a single health score, predicts churn, and exports via Iceberg for organization-wide visibility.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "₱4.8 billion annual revenue across 58 enterprise clients and 5 verticals."

**Action**: Point at ₱4.8B revenue KPI

### [0:45–1:30] CLIENT HEALTH

**Show**: Client Health tab

> "Health score combines delivery (40%), satisfaction (35%), and financial (25%) dimensions."

**Action**: Show health score trend for BankCo

### [1:30–2:15] REVENUE & PORTFOLIO

**Show**: Revenue & Portfolio tab

> "ML.FORECAST projects 8.4% revenue growth next quarter — driven by healthcare vertical."

**Action**: Show revenue forecast chart

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Isabella asks: 'Which vertical grew fastest this year?'"

**Action**: Type: 'Which vertical grew fastest?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Dynamic Tables build health scores → Iceberg export for cross-platform access."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **Iceberg Tables for cross-platform client reports** — Only demo exporting BPO client data to open Iceberg format for Athena/Spark consumers
2. **Dynamic Tables for health scores** — Composite health score combining 3 data domains — declarative, always fresh
3. **ML.CLASSIFICATION for churn risk** — Native churn prediction without SageMaker — SQL-based, no MLOps
4. **Portfolio concentration risk analysis** — Revenue dependency alerts — unique to multi-client services business
5. **Philippine BPO enterprise context** — ₱4.8B portfolio with Fortune 500 client relationships and vertical segmentation


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM CLIENT_PORTFOLIO.RAW.REVENUE_TRANSACTIONS` → 340000
- [ ] `SELECT COUNT(*) FROM CLIENT_PORTFOLIO.RAW.DELIVERY_METRICS` → 580000
- [ ] `SELECT COUNT(DISTINCT CLIENT_ID) FROM CLIENT_PORTFOLIO.CURATED.CLIENT_HEALTH_SCORE WHERE HEALTH_SCORE < 60` → 7

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM CLIENT_PORTFOLIO.ML.CHURN_CLASSIFICATION_RESULTS WHERE CHURN_RISK = 'HIGH'` → >=3
- [ ] `SELECT COUNT(*) FROM CLIENT_PORTFOLIO.ML.REVENUE_FORECAST_RESULTS` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM CLIENT_PORTFOLIO.AI.SURVEY_CLASSIFICATION` → 2400

