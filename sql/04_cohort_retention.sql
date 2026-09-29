-- =====================================================================
-- 04 | CUSTOMER COHORT RETENTION
-- Group customers by the month of their FIRST order, then measure what
-- % of each cohort ordered again 1, 2, ... 6 months later.
-- Output is pivoted into a classic retention matrix (m0 = 100%).
-- =====================================================================

WITH valid_orders AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)   -- complete months only
),

first_order AS (
  SELECT user_id, MIN(order_month) AS cohort_month
  FROM valid_orders
  GROUP BY user_id
),

cohort_activity AS (
  SELECT
    f.cohort_month,
    DATE_DIFF(v.order_month, f.cohort_month, MONTH) AS months_since_first,
    COUNT(DISTINCT v.user_id)                        AS active_customers
  FROM first_order AS f
  JOIN valid_orders AS v
    USING (user_id)
  GROUP BY f.cohort_month, months_since_first
),

retention AS (
  SELECT
    cohort_month,
    months_since_first,
    active_customers,
    FIRST_VALUE(active_customers) OVER (
      PARTITION BY cohort_month ORDER BY months_since_first
    ) AS cohort_size
  FROM cohort_activity
  WHERE cohort_month >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 12 MONTH)
    AND months_since_first BETWEEN 0 AND 6
)

SELECT *
FROM (
  SELECT
    cohort_month,
    cohort_size,
    months_since_first,
    ROUND(SAFE_DIVIDE(active_customers, cohort_size) * 100, 1) AS retention_pct
  FROM retention
)
PIVOT (
  MAX(retention_pct) FOR months_since_first IN (0 AS m0, 1 AS m1, 2 AS m2, 3 AS m3, 4 AS m4, 5 AS m5, 6 AS m6)
)
ORDER BY cohort_month;

-- Note: recent cohorts have NULL in later columns because those months
-- have not happened yet. That is expected, not missing data.
