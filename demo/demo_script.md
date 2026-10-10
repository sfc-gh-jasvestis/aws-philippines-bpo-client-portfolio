# Philippines BPO Client Portfolio

**Philippines - BPO Client Portfolio**
Use case: Escalations, SLA breaches, quality controls and account risk

> Client portfolio monitoring for 40 fictional client accounts of a fictional Philippine BPO provider, served from Quezon City, Cebu City, Davao City, Iloilo City and Bacolod: dynamic tables, a holdout-evaluated SLA breach classifier, an escalation forecast and repeat contact rate anomaly detection, a Cortex Agent with SOP citations, a live interaction feed with an alert, and an SPCS app.

## Why Snowflake

- **Dynamic tables** reconcile contacts, escalations, SLA breaches, service credits and QA audit compliance from RAW account data, with checks in `run_core.py`
- **SLA breach classification** gives a holdout-evaluated next-7-day probability per account
- **Escalation forecast** projects 14 days of portfolio-wide escalations with prediction intervals, for team-lead staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live interactions**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.ACCOUNTS` (40 rows) |
| Fact table | `RAW.ACCOUNT_DAILY` (3,600 account-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `ESCALATION_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.BREACH_RISK_SCORES`, `ML.BREACH_RISK_HOLDOUT_METRICS`, `ML.ESCALATION_FORECAST`, `ML.REPEAT_CONTACT_ANOMALIES` |

Currency: PHP. Delivery site cities: Quezon City, Cebu City, Davao City, Iloilo City, Bacolod.
Client verticals: Financial services, Telecommunications, Retail and e-commerce, Travel and hospitality, Technology support.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Contacts Without Escalation | 99.98% |
| Escalations Raised | 735 |
| SLA Breaches | 231 |
| Escalation Breach Rate | 31.4% |
| Service Credits Issued | 95 |
| Billed Revenue (PHP M) | 576 |
| Contacts Handled | 3,898,275 |
| QA Audit Compliance | 74.0% |
| Client Accounts Monitored | 40 |
| Agent Certification Coverage | 59.4% |
| Agents In Certification Training | 22 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily escalations against SLA breaches, escalations and SLA breaches by escalation type, account table
2. Predictive: holdout metrics, risk bands, 14-day escalation forecast, repeat contact rate anomalies
3. Controls: QA audit compliance, agent certification coverage and agents in training, QA audit compliance against SLA breaches, then generate the action memo
4. Live Interactions: run `CALL APP.SIMULATE_INTERACTIONS(20)` (Snowflake only) or `python aws/publish_interactions.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_INTERACTION_ALERT` and show the alert log and email
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.98% of contacts are handled without an escalation; the 735 escalations are where account teams spend their time, and almost 1 in 3 of them (31.4%) miss the SLA.
- Billing dispute escalations produce the most SLA breaches (57 of 185). Site connectivity outages hit every account at a site at once and are always closed within SLA.
- Cebu City accounts carry the most SLA breaches (73); Quezon City accounts the fewest (16).
- The risk model is evaluated on a time-based holdout: precision 0.57 and recall 0.32 at 0.5, against a 0.26 base rate. Present it as triage, not a verdict.
- Site connectivity outages are excluded from model training, because they are not account-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
