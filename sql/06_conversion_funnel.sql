-- =====================================================================
-- 06 | WEBSITE CONVERSION FUNNEL BY TRAFFIC SOURCE (last 3 complete months)
-- Session-level funnel: product view -> add to cart -> purchase.
-- Which marketing channels bring visitors who actually buy?
-- =====================================================================

WITH sessions AS (
  SELECT
    session_id,
    ANY_VALUE(traffic_source)             AS traffic_source,
    LOGICAL_OR(event_type = 'product')    AS viewed_product,
    LOGICAL_OR(event_type = 'cart')       AS added_to_cart,
    LOGICAL_OR(event_type = 'purchase')   AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  WHERE DATE(created_at) >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 3 MONTH)
    AND DATE(created_at) <  DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY session_id
)

SELECT
  -- alias must differ from the grouped column: if it were also named traffic_source,
  -- BigQuery would group by the alias and the ROLLUP total row would come back blank
  COALESCE(traffic_source, 'ALL SOURCES')                               AS channel,
  COUNT(*)                                                              AS sessions,
  COUNTIF(viewed_product)                                               AS product_view_sessions,
  COUNTIF(added_to_cart)                                                AS cart_sessions,
  COUNTIF(purchased)                                                    AS purchase_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(added_to_cart), COUNTIF(viewed_product)) * 100, 1) AS view_to_cart_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased),     COUNTIF(added_to_cart))  * 100, 1) AS cart_to_purchase_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased),     COUNT(*))                * 100, 1) AS session_conversion_pct
FROM sessions
GROUP BY ROLLUP (traffic_source)
ORDER BY sessions DESC;
