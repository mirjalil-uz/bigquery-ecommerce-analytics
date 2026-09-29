-- =====================================================================
-- 01 | DATA QUALITY CHECKS
-- Goal: understand the tables and confirm the data is trustworthy
--       before building any KPI on top of it.
-- Dataset: bigquery-public-data.thelook_ecommerce (free public dataset)
-- Run each query separately in the BigQuery console.
-- =====================================================================


-- 1A. Row counts, unique keys, and date coverage for each core table
--     (row_count should equal distinct_keys -> no duplicate primary keys)
SELECT 'orders' AS table_name, COUNT(*) AS row_count, COUNT(DISTINCT order_id) AS distinct_keys,
       MIN(created_at) AS first_record, MAX(created_at) AS last_record
FROM `bigquery-public-data.thelook_ecommerce.orders`
UNION ALL
SELECT 'order_items', COUNT(*), COUNT(DISTINCT id), MIN(created_at), MAX(created_at)
FROM `bigquery-public-data.thelook_ecommerce.order_items`
UNION ALL
SELECT 'users', COUNT(*), COUNT(DISTINCT id), MIN(created_at), MAX(created_at)
FROM `bigquery-public-data.thelook_ecommerce.users`
UNION ALL
SELECT 'events', COUNT(*), COUNT(DISTINCT id), MIN(created_at), MAX(created_at)
FROM `bigquery-public-data.thelook_ecommerce.events`
ORDER BY table_name;


-- 1B. Missing or invalid values in the fields used for revenue
SELECT
  COUNT(*)                                   AS total_items,
  COUNTIF(sale_price IS NULL)                AS null_sale_price,
  COUNTIF(sale_price <= 0)                   AS non_positive_sale_price,
  COUNTIF(product_id IS NULL)                AS null_product_id,
  COUNTIF(status IS NULL)                    AS null_status,
  COUNTIF(status = 'Returned' AND returned_at IS NULL)   AS returned_without_date,
  COUNTIF(shipped_at IS NOT NULL AND shipped_at < created_at) AS shipped_before_ordered
FROM `bigquery-public-data.thelook_ecommerce.order_items`;


-- 1C. Orphan check: order items whose product does not exist
SELECT COUNT(*) AS orphan_items
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON p.id = oi.product_id
WHERE p.id IS NULL;


-- 1D. Status distribution (decides which statuses count as revenue)
SELECT
  status,
  COUNT(*) AS items,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_items
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY status
ORDER BY items DESC;


-- 1E. Reconciliation: does orders.num_of_item match the actual item rows?
--     (same idea as reconciling a SQL report against Excel records)
WITH item_counts AS (
  SELECT order_id, COUNT(*) AS actual_items
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY order_id
)
SELECT
  COUNT(*)                                        AS orders_checked,
  COUNTIF(o.num_of_item = ic.actual_items)        AS matching_orders,
  COUNTIF(o.num_of_item != ic.actual_items)       AS mismatched_orders,
  COUNTIF(ic.order_id IS NULL)                    AS orders_without_items
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
LEFT JOIN item_counts AS ic
  ON ic.order_id = o.order_id;
