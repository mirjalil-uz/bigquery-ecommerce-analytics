-- =====================================================================
-- 05 | RFM CUSTOMER SEGMENTATION
-- Score every customer 1-5 on Recency, Frequency and Monetary value,
-- then group them into business-friendly segments.
-- =====================================================================

DECLARE analysis_date DATE DEFAULT DATE_TRUNC(CURRENT_DATE(), MONTH);

WITH customer_stats AS (
  SELECT
    user_id,
    DATE_DIFF(analysis_date, DATE(MAX(created_at)), DAY) AS recency_days,
    COUNT(DISTINCT order_id)                              AS frequency,
    ROUND(SUM(sale_price), 2)                             AS monetary
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < analysis_date
  GROUP BY user_id
),

scored AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,   -- 5 = bought most recently
    NTILE(5) OVER (ORDER BY frequency)         AS f_score,   -- 5 = orders most often
    NTILE(5) OVER (ORDER BY monetary)          AS m_score    -- 5 = spends the most
  FROM customer_stats
),

segmented AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
      WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
      WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
      WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
      WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
      ELSE 'Needs Attention'
    END AS segment
  FROM scored
)

SELECT
  segment,
  COUNT(*)                                                            AS customers,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1)                    AS customer_share_pct,
  ROUND(AVG(recency_days), 0)                                         AS avg_recency_days,
  ROUND(AVG(frequency), 2)                                            AS avg_orders,
  ROUND(AVG(monetary), 2)                                             AS avg_revenue_per_customer,
  ROUND(SUM(monetary), 2)                                             AS total_revenue,
  ROUND(SUM(monetary) / SUM(SUM(monetary)) OVER () * 100, 1)          AS revenue_share_pct
FROM segmented
GROUP BY segment
ORDER BY total_revenue DESC;

-- Known limitation: most customers in this dataset place only 1-2 orders,
-- so many customers tie on frequency. NTILE splits ties arbitrarily.
-- See README "Limitations" for how to handle this.
