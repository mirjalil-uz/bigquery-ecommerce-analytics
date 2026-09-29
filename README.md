# E-Commerce Revenue, Retention & Funnel Analysis — Google BigQuery

End-to-end SQL analysis of an online clothing retailer in **Google BigQuery**, from data-quality checks to a reporting layer that powers a **Looker Studio** dashboard.

**Tools:** Google BigQuery (Standard SQL) · Looker Studio · Power BI (optional)
**Skills shown:** CTEs · window functions (`LAG`, `RANK`, `NTILE`, `FIRST_VALUE`, running totals) · `PIVOT` · `ROLLUP` · `SAFE_DIVIDE` · `APPROX_QUANTILES` · partitioned & clustered tables · views · cost-aware querying

---

## Business problem

An e-commerce company wants to answer five questions:

1. How are **revenue, profit and order volume** trending month over month and year over year?
2. Which **product categories** drive profit, and which lose money through returns?
3. Do customers **come back** after their first order? (cohort retention)
4. Who are our **most valuable customers**, and who is at risk of leaving? (RFM segmentation)
5. Which **marketing channels** bring visitors who actually buy? (conversion funnel)

## Dataset

[`bigquery-public-data.thelook_ecommerce`](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce) — a free public dataset created by Google that simulates a real online store. It has 7 related tables:

| Table | What it contains |
|---|---|
| `orders` | One row per order (status, dates, number of items) |
| `order_items` | One row per item sold (price, status, ship/deliver/return dates) |
| `products` | Product catalog (category, brand, cost, retail price) |
| `users` | Customers (age, gender, location, traffic source) |
| `events` | Website clickstream (page views, cart, purchase) |
| `inventory_items`, `distribution_centers` | Stock and warehouses |

No download needed. Everything runs directly in BigQuery.

## Project structure

```
bigquery-ecommerce-analytics/
├── sql/
│   ├── 01_data_quality_checks.sql      # row counts, nulls, orphans, reconciliation
│   ├── 02_monthly_kpis.sql             # revenue, margin, AOV, MoM & YoY growth
│   ├── 03_category_performance.sql     # category ranking, Pareto, return rates
│   ├── 04_cohort_retention.sql         # monthly cohorts, pivoted retention matrix
│   ├── 05_rfm_segmentation.sql         # RFM scores and customer segments
│   ├── 06_conversion_funnel.sql        # session funnel by traffic source
│   ├── 07_fulfillment_and_returns.sql  # shipping speed & returns by warehouse
│   └── 08_reporting_layer.sql          # partitioned fact table + dashboard views
├── dashboard/
│   └── dashboard_guide.md              # how the Looker Studio dashboard is built
└── results/
    └── (screenshots of query results and the dashboard)
```

## Approach

1. **Validate the data first** (`01`): checked for duplicate keys, missing prices, orphan records and status values, and reconciled `orders.num_of_item` against the actual item rows.
2. **Define metrics clearly**:
   - *Revenue* = sum of `sale_price` for items that were **not Cancelled or Returned**
   - *Gross profit* = revenue − product cost
   - *Return rate* = returned items ÷ non-cancelled items
   - Only **complete months** are used, so a half-finished current month never looks like a drop.
3. **Analyze** trends, categories, retention, segments, funnel and fulfillment (`02`–`07`).
4. **Build a reporting layer** (`08`): a **date-partitioned, clustered** fact table plus views, so the dashboard queries less data and costs less.
5. **Visualize** in Looker Studio (see `dashboard/dashboard_guide.md`).

## Key findings

> Results from queries run on **September 29, 2026**. "Last 12 months" = Sep 2025 – Aug 2026 (complete months only). TheLook refreshes regularly, so numbers change over time.

**Data quality**
- 125,588 orders, 182,295 order items, 100,000 customers and 2.44M website events — **no duplicate keys** in any table.
- Found **future-dated records** (up to Oct 2, 2026, after the run date), so all analysis uses complete months only.
- **Reconciliation:** total category revenue (query 03) matches the monthly KPI total (query 02) **to the cent: $2,833,914.23**.
- **Reporting layer check:** August 2026 revenue from the new partitioned table (query 08E) matches query 02 exactly (**$368,843.36**), confirming the fact table is correct.

**1. Revenue is growing fast with a stable margin**
- **$2.83M revenue** from **33,436 orders** in the last 12 months — **+75.5%** vs the previous 12 months ($1.61M).
- Growth is accelerating: August 2026 revenue was **$368.8K, +127% year over year**.
- **Gross margin is steady at ~52%** every month (51.6%–52.2%) and **average order value is stable at ~$85**, so growth comes from **more orders and customers, not higher prices**.

**2. Revenue is spread across many categories**
- **Outerwear & Coats** leads with **$350.5K (12.4%)**, followed by Jeans (11.5%).
- The top 5 categories bring **43.8%** of revenue; it takes **13 of 26 categories to reach 80%** — no single category dominates.
- **Jeans** is the #2 category but has a lower margin (46.6%) and the **highest returned value ($47.0K)**.
- Returns cost **$370.9K** in the period. Highest return rates: **Suits 14.7%** (small volume) and **Plus 13.2%** among high-volume categories.

**3. Retention is the biggest opportunity**
- Only **~5% of new customers order again the next month** (average month-1 retention **5.2%** across 11 cohorts).
- It is **improving**: month-1 retention rose from **2.9%** (Sep 2025 cohort) to **9.8%** (Jul 2026 cohort).

**4. A quarter of customers drive a third of revenue**
- **Champions: 25.8% of customers generate 34.1% of revenue**.
- **At Risk: 7.8% of customers** with the **highest average spend ($189.52)** but ~1,060 days since their last order — the best win-back target.
- **Hibernating: 32.2% of customers**, inactive for ~3.5 years on average.

**5. Traffic sources convert almost equally**
- All channels convert **56.4%–57.6%** of sessions; Facebook is highest (57.6%).
- **Email (45%) and Adwords (30%)** bring 75% of sessions, so they matter most by volume, not by conversion rate.

**6. Fulfillment is consistent**
- All 10 distribution centers ship in **~0.5 days** with **~2.5 days in transit**, and 90% of orders arrive within **~6 days**.
- Return rates vary only from **15.0% (Savannah)** to **16.3% (Charleston)**, so returns are **not driven by shipping speed**.

## Recommendations

1. **Second-purchase campaign:** email new customers within 30 days of their first order (e.g., recommendations based on the first purchase) to lift month-1 retention above ~5%.
2. **Win back "At Risk" customers:** they spend the most per customer ($190) but have gone quiet, so a targeted offer has high value.
3. **Reduce returns in Jeans and Plus:** review size guides and fit information for these high-return categories.
4. **Keep investing in Email and Adwords** for volume, since conversion is similar across channels.

## BigQuery cost awareness

BigQuery charges by **bytes scanned**, so the queries are written to stay cheap:
- select only needed columns (never `SELECT *` on large tables)
- filter on dates early
- the reporting table is **partitioned by `order_date`** and **clustered by `category` and `traffic_source`**. Query `08E` shows the lower "bytes processed" compared with scanning the raw table.

**Measured result (query 08E vs the same query on the raw tables, August 2026 revenue by category):**

| Query source | Bytes processed | Bytes billed |
|---|---|---|
| Raw public tables (`order_items` + `products` join) | 6.52 MB | 20 MB |
| Partitioned + clustered `fact_order_items` | **232 KB** | 10 MB |

That is **~96% less data scanned (~28× less)** for the same result. The saving comes from two design choices: **partition pruning** (only August's partitions are read) and a **pre-joined fact table** (no scan of `products`). Bytes billed are higher than processed because BigQuery bills a 10 MB minimum per table referenced.

The whole project runs within BigQuery's free tier (1 TB of queries per month).

## Limitations & next steps

- TheLook is **synthetic data**, so patterns are realistic but not from a real company (for example, the nearly identical conversion rates across channels).
- Most customers place only 1–2 orders, so many customers tie on **frequency** in RFM. A next step is to use fixed business thresholds (e.g., 1, 2, 3+ orders) instead of `NTILE` for the F score.
- The funnel counts sessions that contain each event, not a strict step-by-step order.
- Return rate is defined differently in query 03 (returned ÷ non-cancelled items, ~12%) and query 07 (returned ÷ shipped items, ~15%). Both are valid, but the definition must be stated whenever the number is shown.
- Next: schedule the fact table to refresh daily with **BigQuery scheduled queries**, and add a simple customer-lifetime-value estimate.

## How to run it yourself

1. Open the [BigQuery console](https://console.cloud.google.com/bigquery) and create a free project (the **BigQuery Sandbox** needs no credit card).
2. Open a new query tab, paste a file from `sql/`, and click **Run**. Run the files in order.
3. For `08_reporting_layer.sql`, make sure your own project is selected. It creates the `ecommerce_analytics` dataset there.
4. Connect Looker Studio to the `ecommerce_analytics` views (see `dashboard/dashboard_guide.md`).

---

**Author:** Mirjalil Mirfozilov · [LinkedIn](https://www.linkedin.com/in/mirjalil-mirfozilov) · [Portfolio](https://mirjalil-uz.github.io)
