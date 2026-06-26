-- ============================================================
-- Input dataset for Spearman correlation calculated in DAX
-- Filters to sellers with sufficient order history (>= 10)
-- and non-null metrics — excludes WATCH-tier sellers
-- One row per seller
-- ============================================================

CREATE OR REPLACE VIEW mart_seller_correlation AS

SELECT
    seller_id,
    late_delivery_rate,
    avg_review_score
FROM int_seller_metrics
WHERE delivered_orders   >= 10
  AND avg_review_score   IS NOT NULL
  AND late_delivery_rate IS NOT NULL;
