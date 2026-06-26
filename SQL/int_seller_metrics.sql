-- ============================================================
-- Aggregates seller-level operational performance
-- Combines order volume, cancellations, delivery quality,
-- customer satisfaction and revenue metrics
-- One row per seller
-- Note: all_orders uses raw orders table to capture all
-- statuses including canceled — stg_orders filters to
-- delivered only and would exclude cancellations
-- ============================================================

CREATE OR REPLACE VIEW int_seller_metrics AS

WITH all_orders AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)                                          AS all_orders,
        COUNT(DISTINCT CASE WHEN o.order_status = 'canceled' THEN oi.order_id END) AS cancelled_orders
    FROM stg_order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY oi.seller_id
),

seller_perf AS (
    SELECT
        seller_id,
        COUNT(*)                                                          AS delivered_orders,
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END)                         AS late_delivery_count,
        ROUND(AVG(avg_review_score), 2)                                   AS avg_review_score,
        ROUND(AVG(CASE WHEN avg_review_score <= 2 THEN 1 ELSE 0 END), 4) AS low_rating_pct,
        ROUND(SUM(total_revenue), 2)                                      AS total_revenue
    FROM int_order_facts
    GROUP BY seller_id
)

SELECT
    ao.seller_id,
    ao.all_orders,
    COALESCE(sp.delivered_orders, 0)                                            AS delivered_orders,
    ROUND(COALESCE(cancelled_orders::numeric / NULLIF(all_orders, 0), 0), 4)   AS cancellation_rate,
    COALESCE(sp.late_delivery_count, 0)                                         AS late_delivery_count,
    ROUND(COALESCE(sp.late_delivery_count::numeric / NULLIF(sp.delivered_orders, 0), 0), 4) AS late_delivery_rate,
    sp.avg_review_score,
    sp.low_rating_pct,
    COALESCE(sp.total_revenue, 0)                                               AS total_revenue
FROM all_orders ao
LEFT JOIN seller_perf sp ON ao.seller_id = sp.seller_id;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM int_seller_metrics;

-- SELECT MIN(avg_review_score), MAX(avg_review_score), AVG(avg_review_score)
-- FROM int_seller_metrics;

-- SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY late_delivery_rate)
-- FROM int_seller_metrics;
