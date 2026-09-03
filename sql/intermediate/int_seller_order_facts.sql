-- ============================================================
-- Builds one analytical row per order and seller combination
-- Attributes only each seller's own item-level GMV to that seller
-- Flags multi-seller orders where review and lateness are ambiguous
-- ============================================================

CREATE OR REPLACE VIEW int_seller_order_facts AS

WITH seller_order_value AS (
    SELECT
        order_id,
        seller_id,
        SUM(item_gmv)::NUMERIC(14,2) AS seller_order_gmv,
        COUNT(*)                     AS seller_item_count
    FROM stg_order_items
    GROUP BY order_id, seller_id
),

seller_count AS (
    SELECT
        order_id,
        COUNT(*) AS seller_count_in_order
    FROM seller_order_value
    GROUP BY order_id
)

SELECT
    sov.order_id,
    sov.seller_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_year_month,
    sov.seller_order_gmv,
    sov.seller_item_count,
    sc.seller_count_in_order,
    (sc.seller_count_in_order = 1) AS is_single_seller_order,
    r.avg_review_score,
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
    (
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND sc.seller_count_in_order = 1
    ) AS is_delivery_quality_eligible,
    (
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND sc.seller_count_in_order = 1
        AND r.avg_review_score IS NOT NULL
    ) AS is_review_quality_eligible
FROM seller_order_value sov
JOIN seller_count sc
    ON sov.order_id = sc.order_id
JOIN stg_orders o
    ON sov.order_id = o.order_id
LEFT JOIN stg_reviews r
    ON sov.order_id = r.order_id;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT order_id, seller_id, COUNT(*) AS rows
-- FROM int_seller_order_facts
-- GROUP BY order_id, seller_id
-- HAVING COUNT(*) > 1;

-- SELECT seller_count_in_order, COUNT(DISTINCT order_id) AS orders
-- FROM int_seller_order_facts
-- WHERE is_delivered_eligible
-- GROUP BY seller_count_in_order
-- ORDER BY seller_count_in_order;

-- SELECT
--     ROUND(SUM(seller_order_gmv), 2) AS seller_order_gmv,
--     (
--         SELECT ROUND(SUM(order_gmv), 2)
--         FROM int_order_facts
--         WHERE is_delivered_eligible
--     ) AS order_gmv
-- FROM int_seller_order_facts
-- WHERE is_delivered_eligible;

-- ============================================================
