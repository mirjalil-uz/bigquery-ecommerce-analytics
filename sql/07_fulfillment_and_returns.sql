-- =====================================================================
-- 07 | FULFILLMENT SPEED & RETURNS BY DISTRIBUTION CENTER (last 12 complete months)
-- Are some warehouses slower to ship, and does that relate to returns?
-- =====================================================================

SELECT
  dc.name                                                                   AS distribution_center,
  COUNT(*)                                                                  AS items_shipped,
  ROUND(AVG(TIMESTAMP_DIFF(oi.shipped_at,   oi.created_at, HOUR)) / 24, 1) AS avg_days_to_ship,
  ROUND(AVG(TIMESTAMP_DIFF(oi.delivered_at, oi.shipped_at, HOUR)) / 24, 1) AS avg_days_in_transit,
  ROUND(APPROX_QUANTILES(TIMESTAMP_DIFF(oi.delivered_at, oi.created_at, HOUR), 100)[OFFSET(90)] / 24, 1)
                                                                            AS p90_days_order_to_delivery,
  ROUND(SAFE_DIVIDE(COUNTIF(oi.status = 'Returned'), COUNT(*)) * 100, 1)    AS return_rate_pct
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON p.id = oi.product_id
JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc
  ON dc.id = p.distribution_center_id
WHERE oi.shipped_at IS NOT NULL
  AND DATE(oi.created_at) >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 12 MONTH)
  AND DATE(oi.created_at) <  DATE_TRUNC(CURRENT_DATE(), MONTH)
GROUP BY distribution_center
ORDER BY return_rate_pct DESC;

-- AVG and APPROX_QUANTILES ignore NULLs, so items not yet delivered
-- do not distort the delivery-time metrics.
