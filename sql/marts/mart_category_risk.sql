-- ============================================================
-- Calculates category risk directly from delivered order items
-- Assigns every item to its actual seller and product category
-- Removes primary-seller and primary-category attribution entirely
-- ============================================================

CREATE OR REPLACE VIEW mart_category_risk AS

WITH delivered_items AS (
    SELECT
        p.product_category_en AS category_en,
        oi.seller_id,
        r.risk_tier,
        oi.item_gmv
    FROM stg_order_items oi
    JOIN stg_orders o
        ON oi.order_id = o.order_id
    LEFT JOIN stg_products p
        ON oi.product_id = p.product_id
    JOIN mart_seller_risk r
        ON oi.seller_id = r.seller_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),

category_tier AS (
    SELECT
        category_en,
        risk_tier,
        COUNT(DISTINCT seller_id) AS seller_count,
        SUM(item_gmv)::NUMERIC(14,2) AS category_risk_gmv
    FROM delivered_items
    GROUP BY category_en, risk_tier
)

SELECT
    category_en,
    risk_tier,
    seller_count,
    ROUND(category_risk_gmv, 2) AS category_risk_gmv,
    ROUND(
        SUM(category_risk_gmv) OVER (PARTITION BY category_en),
        2
    ) AS category_total_gmv,
    ROUND(
        100.0 * category_risk_gmv
        / NULLIF(SUM(category_risk_gmv) OVER (PARTITION BY category_en), 0),
        2
    ) AS pct_of_category_gmv
FROM category_tier;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT
--     ROUND(SUM(category_risk_gmv), 2) AS category_gmv,
--     (
--         SELECT ROUND(SUM(order_gmv), 2)
--         FROM int_order_facts
--         WHERE is_delivered_eligible
--     ) AS order_gmv
-- FROM mart_category_risk;

-- SELECT category_en, SUM(pct_of_category_gmv) AS pct_sum
-- FROM mart_category_risk
-- GROUP BY category_en
-- HAVING ABS(SUM(pct_of_category_gmv) - 100) > 0.10;

-- ============================================================
