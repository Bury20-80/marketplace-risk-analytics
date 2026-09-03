-- ============================================================
-- Preserves the order-item to product to seller relationship
-- Calculates GMV as item price plus freight value
-- Keeps the atomic grain required for seller and category analysis
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
    (price + freight_value)::NUMERIC(12,2) AS item_gmv
FROM order_items;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) AS rows
-- FROM stg_order_items;

-- SELECT COUNT(*) AS invalid_value_rows
-- FROM stg_order_items
-- WHERE price IS NULL
--    OR freight_value IS NULL
--    OR price < 0
--    OR freight_value < 0;

-- ============================================================
