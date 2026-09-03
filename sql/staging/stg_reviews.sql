-- ============================================================
-- Aggregates multiple review rows to one record per order
-- Uses the observed mean score when an order has multiple reviews
-- Preserves review_count so the aggregation remains transparent
-- ============================================================

CREATE OR REPLACE VIEW stg_reviews AS

SELECT
    order_id,
    AVG(review_score)::NUMERIC(4,2) AS avg_review_score,
    COUNT(*)                        AS review_count
FROM order_reviews
GROUP BY order_id;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) AS rows, COUNT(DISTINCT order_id) AS unique_orders
-- FROM stg_reviews;

-- SELECT COUNT(*) AS orders_with_multiple_review_rows
-- FROM stg_reviews
-- WHERE review_count > 1;

-- ============================================================
