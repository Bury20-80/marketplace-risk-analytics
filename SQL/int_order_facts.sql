-- ============================================================
-- Builds a single analytical record per delivered order
-- Assigns primary seller based on highest revenue contribution
-- Category taken from seller's highest revenue product
-- Tiebreaker on seller_id (alphabetical) — deterministic
-- but arbitrary; affects negligible number of orders
-- ============================================================

CREATE OR REPLACE VIEW int_order_facts AS

WITH seller_rank AS (
    SELECT
        oi.order_id,
        oi.seller_id,
        SUM(oi.total_item_revenue) AS seller_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY oi.order_id
            ORDER BY SUM(oi.total_item_revenue) DESC, oi.seller_id
        ) AS seller_rn
    FROM stg_order_items oi
    GROUP BY oi.order_id, oi.seller_id
),

primary_seller AS (
    SELECT order_id, seller_id, seller_revenue
    FROM seller_rank
    WHERE seller_rn = 1
),

category_rank AS (
    SELECT
        oi.order_id,
        oi.seller_id,
        p.product_category_en,
        SUM(oi.total_item_revenue) AS category_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY oi.order_id, oi.seller_id
            ORDER BY SUM(oi.total_item_revenue) DESC
        ) AS category_rn
    FROM stg_order_items oi
    LEFT JOIN stg_products p ON oi.product_id = p.product_id
    GROUP BY oi.order_id, oi.seller_id, p.product_category_en
),

primary_order AS (
    SELECT ps.order_id, ps.seller_id, cr.product_category_en
    FROM primary_seller ps
    LEFT JOIN category_rank cr
        ON ps.order_id  = cr.order_id
       AND ps.seller_id = cr.seller_id
       AND cr.category_rn = 1
),

order_revenue AS (
    SELECT order_id, SUM(total_item_revenue)::NUMERIC(12,2) AS total_revenue
    FROM stg_order_items
    GROUP BY order_id
)

SELECT
    o.order_id,
    po.seller_id,
    o.order_year_month,
    orv.total_revenue,
    r.avg_review_score,
    ROUND((o.order_delivered_customer_date::date - o.order_purchase_timestamp::date)::numeric,   1) AS delivery_days_total,
    ROUND((o.order_estimated_delivery_date::date - o.order_delivered_customer_date::date)::numeric, 1) AS delivery_days_vs_estimate,
    (o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date)                AS is_late,
    po.product_category_en,
    c.customer_state
FROM stg_orders o
LEFT JOIN order_revenue orv ON o.order_id  = orv.order_id
LEFT JOIN primary_order  po  ON o.order_id  = po.order_id
LEFT JOIN stg_reviews    r   ON o.order_id  = r.order_id
LEFT JOIN customers      c   ON o.customer_id = c.customer_id;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM int_order_facts;

-- Grain check — should return 0
-- SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM int_order_facts;

-- is_late sanity — orders with delivery_days_vs_estimate = 0 should never be late
-- SELECT is_late, COUNT(*)
-- FROM int_order_facts
-- WHERE delivery_days_vs_estimate = 0
-- GROUP BY is_late;
