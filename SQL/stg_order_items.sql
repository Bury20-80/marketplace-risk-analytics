-- ============================================================
-- Preserves the order → product → seller relationship
-- Calculates GMV at single line-item level (price + freight)
-- Prepares data for primary seller assignment downstream
-- ============================================================

CREATE OR REPLACE VIEW stg_order_items AS

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    (COALESCE(price, 0) + COALESCE(freight_value, 0))::NUMERIC(12,2) AS total_item_revenue
FROM order_items;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM stg_order_items;
-- SELECT MIN(total_item_revenue), MAX(total_item_revenue) FROM stg_order_items;
