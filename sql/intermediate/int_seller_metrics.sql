-- ============================================================
-- Aggregates seller metrics from the seller-order fact table
-- Separates GMV attribution from ambiguous order-level quality data
-- Uses only single-seller orders for review and lateness metrics
-- ============================================================

CREATE OR REPLACE VIEW int_seller_metrics AS

WITH seller_agg AS (
    SELECT
        seller_id,
        COUNT(*) AS all_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'canceled'
        ) AS cancelled_orders,
        COUNT(*) FILTER (
            WHERE is_delivered_eligible
        ) AS delivered_orders,
        COUNT(*) FILTER (
            WHERE is_delivery_quality_eligible
        ) AS delivery_quality_orders,
        COUNT(*) FILTER (
            WHERE is_review_quality_eligible
        ) AS review_quality_orders,
        COUNT(*) FILTER (
            WHERE is_delivery_quality_eligible
              AND is_late
        ) AS late_delivery_count,
        AVG(avg_review_score) FILTER (
            WHERE is_review_quality_eligible
        ) AS avg_review_score_raw,
        AVG(
            CASE
                WHEN is_review_quality_eligible
                 AND avg_review_score <= 2 THEN 1.0
                WHEN is_review_quality_eligible THEN 0.0
                ELSE NULL
            END
        ) AS low_rating_pct_raw,
        SUM(seller_order_gmv) FILTER (
            WHERE is_delivered_eligible
        ) AS seller_gmv
    FROM int_seller_order_facts
    GROUP BY seller_id
)

SELECT
    seller_id,
    all_orders,
    delivered_orders,
    cancelled_orders,
    ROUND(
        cancelled_orders::NUMERIC / NULLIF(all_orders, 0),
        4
    ) AS cancellation_rate,
    delivery_quality_orders,
    review_quality_orders,
    late_delivery_count,
    ROUND(
        late_delivery_count::NUMERIC / NULLIF(delivery_quality_orders, 0),
        4
    ) AS late_delivery_rate,
    ROUND(avg_review_score_raw::NUMERIC, 2) AS avg_review_score,
    ROUND(low_rating_pct_raw::NUMERIC, 4) AS low_rating_pct,
    ROUND(COALESCE(seller_gmv, 0)::NUMERIC, 2) AS seller_gmv
FROM seller_agg;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) AS rows, COUNT(DISTINCT seller_id) AS unique_sellers
-- FROM int_seller_metrics;

-- SELECT
--     COUNT(*) FILTER (WHERE avg_review_score IS NULL) AS sellers_without_review_metric,
--     COUNT(*) FILTER (WHERE late_delivery_rate IS NULL) AS sellers_without_delivery_metric
-- FROM int_seller_metrics;

-- SELECT
--     ROUND(SUM(seller_gmv), 2) AS seller_gmv,
--     (
--         SELECT ROUND(SUM(order_gmv), 2)
--         FROM int_order_facts
--         WHERE is_delivered_eligible
--     ) AS order_gmv
-- FROM int_seller_metrics;

-- ============================================================
