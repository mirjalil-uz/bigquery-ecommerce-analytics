-- =====================================================================
-- 08 | REPORTING LAYER (tables + views for the dashboard)
-- Creates a dataset in YOUR project with:
--   * a partitioned + clustered fact table (fast, cheap to query)
--   * views that the Looker Studio / Power BI dashboard reads from
--
-- Before running: in the BigQuery console, make sure your own project
-- is selected at the top. The dataset "ecommerce_analytics" is created there.
-- Sandbox note: free-sandbox tables expire after 60 days; re-run this
-- script to rebuild them.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS ecommerce_analytics
OPTIONS (location = 'US');   -- public dataset lives in the US multi-region


-- 8A. Fact table: one row per order item, enriched with product + customer info.
--     PARTITION BY order_date -> queries filtered by date scan only those days.
--     CLUSTER BY category, traffic_source -> faster filters on common dimensions.
CREATE OR REPLACE TABLE ecommerce_analytics.fact_order_items
PARTITION BY order_date
CLUSTER BY category, traffic_source
AS
SELECT
  oi.id                              AS order_item_id,
  oi.order_id,
  oi.user_id,
  DATE(oi.created_at)                AS order_date,
  oi.status,
  oi.status NOT IN ('Cancelled', 'Returned') AS is_revenue,
  oi.sale_price,
  p.cost,
  oi.sale_price - p.cost             AS gross_profit,
  p.category,
  p.brand,
  p.department,
  u.country,
  u.state,
  u.age,
  u.gender,
  u.traffic_source
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p ON p.id = oi.product_id
JOIN `bigquery-public-data.thelook_ecommerce.users`    AS u ON u.id = oi.user_id
WHERE DATE(oi.created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH);


-- 8B. Monthly KPI view (dashboard page 1)
CREATE OR REPLACE VIEW ecommerce_analytics.v_monthly_kpis AS
SELECT
  DATE_TRUNC(order_date, MONTH)                                  AS month,
  COUNT(DISTINCT IF(is_revenue, order_id, NULL))                 AS orders,
  COUNT(DISTINCT IF(is_revenue, user_id,  NULL))                 AS customers,
  ROUND(SUM(IF(is_revenue, sale_price,   0)), 2)                 AS revenue,
  ROUND(SUM(IF(is_revenue, gross_profit, 0)), 2)                 AS gross_profit,
  ROUND(SAFE_DIVIDE(COUNTIF(status = 'Returned'),
                    COUNTIF(status != 'Cancelled')) * 100, 1)    AS return_rate_pct
FROM ecommerce_analytics.fact_order_items
GROUP BY month;


-- 8C. Category x month view (dashboard page 2)
CREATE OR REPLACE VIEW ecommerce_analytics.v_category_monthly AS
SELECT
  DATE_TRUNC(order_date, MONTH)                  AS month,
  category,
  department,
  COUNTIF(is_revenue)                            AS units_sold,
  ROUND(SUM(IF(is_revenue, sale_price,   0)), 2) AS revenue,
  ROUND(SUM(IF(is_revenue, gross_profit, 0)), 2) AS gross_profit,
  COUNTIF(status = 'Returned')                   AS units_returned
FROM ecommerce_analytics.fact_order_items
GROUP BY month, category, department;


-- 8D. Customer geography / channel view (dashboard page 3)
CREATE OR REPLACE VIEW ecommerce_analytics.v_customers_by_channel AS
SELECT
  traffic_source,
  country,
  COUNT(DISTINCT user_id)                        AS customers,
  ROUND(SUM(IF(is_revenue, sale_price, 0)), 2)   AS revenue,
  ROUND(SAFE_DIVIDE(SUM(IF(is_revenue, sale_price, 0)),
                    COUNT(DISTINCT user_id)), 2) AS revenue_per_customer
FROM ecommerce_analytics.fact_order_items
GROUP BY traffic_source, country;


-- 8E. Proof that partitioning saves cost:
--     Run this, then check "Bytes processed" in the query results panel.
--     Compare it with the same query on the unpartitioned public table.
SELECT category, ROUND(SUM(sale_price), 2) AS revenue
FROM ecommerce_analytics.fact_order_items
WHERE order_date BETWEEN DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH)
                     AND DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 DAY)
  AND is_revenue
GROUP BY category
ORDER BY revenue DESC;
