-- =====================================================================
-- 03 | CATEGORY PERFORMANCE (last 12 complete months)
-- Which product categories drive revenue and profit, and which ones
-- lose money through returns?
-- =====================================================================

WITH items AS (
  SELECT
    p.category,
    oi.status,
    oi.sale_price,
    p.cost
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON p.id = oi.product_id
  WHERE DATE(oi.created_at) >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 12 MONTH)
    AND DATE(oi.created_at) <  DATE_TRUNC(CURRENT_DATE(), MONTH)
),

by_category AS (
  SELECT
    category,
    COUNTIF(status NOT IN ('Cancelled', 'Returned'))                              AS units_sold,
    ROUND(SUM(IF(status NOT IN ('Cancelled', 'Returned'), sale_price, 0)), 2)        AS revenue,
    ROUND(SUM(IF(status NOT IN ('Cancelled', 'Returned'), sale_price - cost, 0)), 2) AS gross_profit,
    ROUND(SUM(IF(status = 'Returned', sale_price, 0)), 2)                            AS returned_value,
    ROUND(SAFE_DIVIDE(COUNTIF(status = 'Returned'),
                      COUNTIF(status != 'Cancelled')) * 100, 1)                     AS return_rate_pct
  FROM items
  GROUP BY category
)

SELECT
  RANK() OVER (ORDER BY revenue DESC)                          AS revenue_rank,
  category,
  units_sold,
  revenue,
  gross_profit,
  ROUND(SAFE_DIVIDE(gross_profit, revenue) * 100, 1)           AS gross_margin_pct,
  ROUND(SAFE_DIVIDE(revenue, SUM(revenue) OVER ()) * 100, 1)   AS revenue_share_pct,
  ROUND(SUM(revenue) OVER (ORDER BY revenue DESC)
        / SUM(revenue) OVER () * 100, 1)                       AS cumulative_share_pct,  -- Pareto (80/20) view
  return_rate_pct,
  returned_value
FROM by_category
ORDER BY revenue_rank;
