-- ============================================================
-- RUN FIRST — must exist before stg_orders and downstream views
-- Deduplicates reviews: some orders have multiple review rows
-- Aggregates to one record per order with averaged score
-- ============================================================

CREATE OR REPLACE VIEW stg_reviews AS

SELECT
    order_id,
    AVG(review_score)::NUMERIC(3,2) AS avg_review_score,
    COUNT(*)                        AS review_count
FROM order_reviews
GROUP BY order_id;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM stg_reviews;
-- SELECT COUNT(DISTINCT order_id) FROM order_reviews;
-- stg_reviews rows < order_reviews rows where review_count > 1
