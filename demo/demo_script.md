# Client Portfolio & Revenue Analytics

**Philippines - BPO & IT Services**
Use case: Client Portfolio Analytics

> Philippine BPOs manage multi-billion peso client portfolios — Snowflake builds real-time client health scores with Dynamic Tables, exports to Iceberg for cross-platform reporting, and enables revenue intelligence at scale.

## Why Snowflake

Snowflake consolidates client revenue, delivery, and satisfaction data into Dynamic Table health scores, exports to Iceberg for cross-platform access, and provides Cortex Agent-powered portfolio intelligence for account managers

- **Iceberg Tables for cross-platform client reports** - Only demo exporting BPO client data to open Iceberg format for Athena/Spark consumers
- **Dynamic Tables for health scores** - Composite health score combining 3 data domains — declarative, always fresh
- **ML.CLASSIFICATION for churn risk** - Native churn prediction without SageMaker — SQL-based, no MLOps
- **Portfolio concentration risk analysis** - Revenue dependency alerts — unique to multi-client services business
- **Philippine BPO enterprise context** - ₱4.8B portfolio with Fortune 500 client relationships and vertical segmentation

## What is deployed

| | |
|---|---|
| Database | `PH_BPO_CLIENT_PORTFOLIO` |
| Service | `PH_BPO_CLIENT_PORTFOLIO_APP` |
| Compute pool | `SEA_DEMOS_PHILIPPINES_POOL` |
| Dimension table | `RAW.CLIENTS` (20 rows) |
| Fact table | `RAW.DELIVERY_METRICS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | PHP (₱) |

Regions in play: Metro Manila, Cebu, Davao, Pampanga, Iloilo
Segments: Telco Client, Banking Client, Retail Client, Healthcare Client

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh PH_BPO_CLIENT_PORTFOLIO
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Portfolio Revenue | `₱18.4B` | total across Clients |
| Client Retention | `94%` | average per event |
| At-Risk Accounts | `4` | total across Clients |
| Active Clients | `87` | total across Clients |
| Pipeline Value | `₱4.2B` | total across Clients |
| Cross-Sell Rate | `28%` | average per event |
| Avg Contract Length | `3.2 yrs` | average per event |


## Demo flow

1. Executive Cockpit
2. Client Health
3. Revenue & Portfolio
4. Ask AI
5. Architecture & Data

## Talking points

- **₱4.8B** - annual revenue across 58 enterprise clients
- **7 clients** - below 60 health score (at-risk)
- **3 renewals** - within 90 days for at-risk clients (₱620M exposure)
- **16.2%** - revenue concentration in top client (above threshold)
- **₱340M** - upsell pipeline identified by AI
- **8.4%** - forecasted revenue growth next quarter

## Business impact

- Client retention improvement of 5% increases BPO profitability by 25-95% (Bain & Company)
- Philippines IT-BPM revenue reached $32.5B in 2023 with 8.4% growth (IBPAP)
- Proactive account management reduces churn 20-30% in professional services (McKinsey B2B)
- Open table formats like Iceberg reduce data platform lock-in costs by 40% (Snowflake Engineering)

---
Generated from `generator/demo_specs/aws-philippines-bpo-client-portfolio.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-philippines-bpo-client-portfolio` instead.
