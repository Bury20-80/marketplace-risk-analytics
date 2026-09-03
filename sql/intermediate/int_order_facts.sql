-- ============================================================
-- Builds the order-level analytical fact table
-- Keeps only attributes that genuinely belong to the full order
-- Removes arbitrary primary-seller and primary-category assignment
-- ============================================================

CREATE OR REPLACE VIEW int_order_facts AS

WITH order_value AS (
    SELECT
        order_id,
        SUM(item_gmv)::NUMERIC(14,2) AS order_gmv,
        COUNT(*)                     AS item_count,
        COUNT(DISTINCT seller_id)    AS seller_count
    FROM stg_order_items
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_year_month,
    ov.order_gmv,
    COALESCE(ov.item_count, 0)   AS item_count,
    COALESCE(ov.seller_count, 0) AS seller_count,
    r.avg_review_score,
    r.review_count,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN o.order_delivered_customer_date::date - o.order_purchase_timestamp::date
        ELSE NULL
    END AS delivery_days_total,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_estimated_delivery_date::date - o.order_delivered_customer_date::date
        ELSE NULL
    END AS delivery_days_vs_estimate,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
        ELSE NULL
    END AS is_late,
    (
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
    ) AS is_delivered_eligible,
    c.customer_state
FROM stg_orders o
LEFT JOIN order_value ov
    ON o.order_id = ov.order_id
LEFT JOIN stg_reviews r
    ON o.order_id = r.order_id
LEFT JOIN customers c
    ON o.customer_id = c.customer_id;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
-- FROM int_order_facts;

-- SELECT ROUND(SUM(order_gmv), 2) AS delivered_order_gmv
-- FROM int_order_facts
-- WHERE is_delivered_eligible;

-- SELECT COUNT(*) AS orders_without_items
-- FROM int_order_facts
-- WHERE order_gmv IS NULL;

-- ============================================================
