# Query results log

Queries run on **2026-09-29** in project "My Project 47999".

## 01A — Row counts & key uniqueness
| table | row_count | distinct_keys | first_record | last_record |
|---|---|---|---|---|
| events | 2,435,494 | 2,435,494 | 2019-01-02 | 2026-10-02 |
| order_items | 182,295 | 182,295 | 2019-01-09 | 2026-10-02 |
| orders | 125,588 | 125,588 | 2019-01-09 | 2026-09-29 |
| users | 100,000 | 100,000 | 2019-01-02 | 2026-09-28 |

**Findings:** no duplicate primary keys in any table. `events` and `order_items` contain **future-dated records** (up to 2026-10-02, after the run date) — handled by restricting all analysis to complete months (< 2026-09-01).

## 02 — Monthly KPIs (last 12 complete months, Sep 2025 – Aug 2026)
- Revenue **$2,833,914.23**, gross profit $1,472,903.51, **margin 52.0%**, 33,436 orders, **AOV $84.76**
- Previous 12 months revenue $1,614,829.08 → **+75.5% YoY**
- Aug 2026: $368,843.36 revenue, **+127.0% YoY**, +13.4% MoM
- Monthly margin range 51.6%–52.2%; AOV range $79.97–$88.18

## 03 — Category performance (last 12 complete months)
- #1 Outerwear & Coats $350,549.90 (12.4%), #2 Jeans $325,633.85 (11.5%), #3 Sweaters (7.7%)
- Top 5 = 43.8% of revenue; 13 of 26 categories = 80.7%
- Total returned value $370,917.60; highest return rate Suits 14.7% (279 units); Plus 13.2% (high volume)
- **Reconciliation:** category revenue total = query 02 total ($2,833,914.23) ✅

## 04 — Cohort retention (Sep 2025 – Aug 2026 cohorts)
- Month-1 retention average 5.2% (11 cohorts; size-weighted 5.5%); range 2.9% (Sep 2025) → 9.8% (Jul 2026)

## 05 — RFM segments (61,767 customers)
- Champions 25.8% of customers / 34.1% of revenue
- Loyal 26.3% / 24.9% · Hibernating 32.2% / 23.2% · At Risk 7.8% / 12.3% (avg spend $189.52) · New/Promising 7.8% / 5.5% · Needs Attention 4 customers

## 06 — Funnel (Jun – Aug 2026)
- 37,834 sessions, 56.9% session conversion overall
- Facebook 57.6% (highest), Adwords 57.0%, Email 56.9%, YouTube 56.8%, Organic 56.4%
- Email 16,976 sessions (45%), Adwords 11,482 (30%)
- Bug found: the total row came back blank because the COALESCE alias had the same name as the grouped column — fixed in the SQL file

## 07 — Fulfillment (last 12 complete months)
- All DCs: ~0.5–0.6 days to ship, 2.4–2.6 days in transit, P90 5.8–6.0 days
- Return rate 15.0% (Savannah GA) – 16.3% (Charleston SC)
- Note: 07 return rate = returned ÷ shipped items; 03 = returned ÷ non-cancelled items → different denominators

## 08 — Partitioning cost check
- Not run yet
