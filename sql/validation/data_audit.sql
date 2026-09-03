-- ============================================================
-- Audits raw tables required by the analytical model
-- Checks keys, NULLs, invalid monetary values and foreign keys
-- Quantifies multi-seller orders that motivate the corrected grain
-- ============================================================

SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS non_null_key_rows,
    COUNT(DISTINCT customer_id) AS distinct_key_rows
FROM customers

UNION ALL
SELECT 'orders', COUNT(*), COUNT(order_id), COUNT(DISTINCT order_id)
FROM orders

UNION ALL
SELECT 'products', COUNT(*), COUNT(product_id), COUNT(DISTINCT product_id)
FROM products

UNION ALL
SELECT 'sellers', COUNT(*), COUNT(seller_id), COUNT(DISTINCT seller_id)
FROM sellers

UNION ALL
SELECT 'order_items', COUNT(*), COUNT(order_id), COUNT(DISTINCT order_id)
FROM order_items

UNION ALL
SELECT 'order_reviews', COUNT(*), COUNT(order_id), COUNT(DISTINCT order_id)
FROM order_reviews;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_ids,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_ids,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_ids,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_prices,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight,
    COUNT(*) FILTER (WHERE price < 0) AS negative_prices,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight
FROM order_items;

SELECT
    COUNT(*) FILTER (WHERE o.order_id IS NULL) AS item_rows_without_order,
    COUNT(*) FILTER (WHERE p.product_id IS NULL) AS item_rows_without_product,
    COUNT(*) FILTER (WHERE s.seller_id IS NULL) AS item_rows_without_seller
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id;

SELECT
    COUNT(*) AS delivered_orders_missing_delivery_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

WITH sellers_per_order AS (
    SELECT
        oi.order_id,
        COUNT(DISTINCT oi.seller_id) AS seller_count
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY oi.order_id
)

SELECT
    seller_count,
    COUNT(*) AS delivered_orders
FROM sellers_per_order
GROUP BY seller_count
ORDER BY seller_count;

-- ============================================================
-- Expected result
-- Key checks should show no duplicate business keys or broken joins
-- Multi-seller distribution is descriptive and must not be forced to zero
-- ============================================================
