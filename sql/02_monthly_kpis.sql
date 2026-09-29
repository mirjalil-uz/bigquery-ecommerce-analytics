-- =====================================================================
-- 02 | MONTHLY BUSINESS KPIs (last 24 complete months)
-- Revenue, gross profit, margin, orders, customers, average order value,
-- plus month-over-month and year-over-year growth.
--
-- Revenue rule: an item counts as revenue unless it was Cancelled or Returned.
-- The current (incomplete) month is excluded so trends are not distorted.
-- =====================================================================

WITH items AS (
  SELECT
    DATE_TRUNC(DATE(oi.created_at), MONTH) AS month,
    oi.order_id,
    oi.user_id,
    oi.sale_price,
    p.cost
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON p.id = oi.product_id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND DATE(oi.created_at) >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 24 MONTH)
    AND DATE(oi.created_at) <  DATE_TRUNC(CURRENT_DATE(), MONTH)
),

monthly AS (
  SELECT
    month,
    COUNT(DISTINCT order_id)          AS orders,
    COUNT(DISTINCT user_id)           AS customers,
    ROUND(SUM(sale_price), 2)         AS revenue,
    ROUND(SUM(sale_price - cost), 2)  AS gross_profit
  FROM items
  GROUP BY month
)

SELECT
  month,
  orders,
  customers,
  revenue,
  gross_profit,
  ROUND(SAFE_DIVIDE(gross_profit, revenue) * 100, 1)                    AS gross_margin_pct,
  ROUND(SAFE_DIVIDE(revenue, orders), 2)                                AS avg_order_value,
  ROUND(SAFE_DIVIDE(revenue - LAG(revenue) OVER (ORDER BY month),
                    LAG(revenue) OVER (ORDER BY month)) * 100, 1)       AS revenue_mom_growth_pct,
  ROUND(SAFE_DIVIDE(revenue - LAG(revenue, 12) OVER (ORDER BY month),
                    LAG(revenue, 12) OVER (ORDER BY month)) * 100, 1)   AS revenue_yoy_growth_pct,
  ROUND(SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month)
                           ORDER BY month), 2)                          AS revenue_ytd
FROM monthly
ORDER BY month;
