-- ============================================================
-- Prepares the seller-level dataset used for Spearman correlation
-- Requires sufficient review and delivery observations per seller
-- Leaves coefficient and p-value calculation to Python SciPy
-- ============================================================

CREATE OR REPLACE VIEW mart_seller_correlation AS

SELECT
    seller_id,
    delivery_quality_orders,
    review_quality_orders,
    late_delivery_rate,
    avg_review_score
FROM int_seller_metrics
WHERE delivery_quality_orders >= 10
  AND review_quality_orders >= 10
  AND late_delivery_rate IS NOT NULL
  AND avg_review_score IS NOT NULL;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT
--     COUNT(*) AS eligible_sellers,
--     MIN(avg_review_score) AS min_review,
--     MAX(avg_review_score) AS max_review,
--     MIN(late_delivery_rate) AS min_late_rate,
--     MAX(late_delivery_rate) AS max_late_rate
-- FROM mart_seller_correlation;

-- ============================================================
