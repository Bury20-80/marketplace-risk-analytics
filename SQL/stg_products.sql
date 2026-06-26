-- ============================================================
-- Translates category names from Portuguese to English
-- Falls back to Portuguese name then 'Unknown' via COALESCE
-- Simplifies category handling in all downstream joins
-- ============================================================

CREATE OR REPLACE VIEW stg_products AS

SELECT
    p.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category_en
FROM products p
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM stg_products;
-- SELECT COUNT(*) FROM stg_products WHERE product_category_en = 'Unknown';
