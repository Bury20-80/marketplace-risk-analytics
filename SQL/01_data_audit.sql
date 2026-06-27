-- ============================================================
-- OLIST E-COMMERCE — PHASE 1: DATA AUDIT & BUSINESS EXPLORATION
-- Run AFTER all SQL layers are built (staging → intermediate → marts)
-- Each query answers a specific business question
-- ============================================================
-- QUERY 1: DATA AUDIT
-- Business question: "Is our data complete and trustworthy?"
-- Why it matters: You never skip this in a real job.
-- Shows data quality 
-- ============================================================

SELECT
    'customers'             AS table_name,
    COUNT(*)                AS total_rows,
    COUNT(customer_id)      AS non_null_pk,
    COUNT(DISTINCT customer_id) AS unique_pk
FROM customers

UNION ALL

SELECT
    'orders',
    COUNT(*),
    COUNT(order_id),
    COUNT(DISTINCT order_id)
FROM orders

UNION ALL

SELECT
    'order_items',
    COUNT(*),
    COUNT(order_id),
    COUNT(DISTINCT order_id)
FROM order_items

UNION ALL

SELECT
    'order_payments',
    COUNT(*),
    COUNT(order_id),
    COUNT(DISTINCT order_id)
FROM order_payments

UNION ALL

SELECT
    'order_reviews',
    COUNT(*),
    COUNT(order_id),
    COUNT(DISTINCT order_id)
FROM order_reviews

UNION ALL

SELECT
    'products',
    COUNT(*),
    COUNT(product_id),
    COUNT(DISTINCT product_id)
FROM products

UNION ALL

SELECT
    'sellers',
    COUNT(*),
    COUNT(seller_id),
    COUNT(DISTINCT seller_id)
FROM sellers;


-- ============================================================
-- QUERY 2: NULL AUDIT ON KEY COLUMNS
-- Business question: "What data gaps will affect our analysis?"
-- Note: Document NULL counts before touching any analysis.
-- This is basically Power Query
-- ============================================================

SELECT
    'orders — order_delivered_customer_date'    AS column_name,
    COUNT(*)                                    AS total_rows,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_count,
    ROUND(
        SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS null_pct
FROM orders

UNION ALL

SELECT
    'orders — order_approved_at',
    COUNT(*),
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM orders

UNION ALL

SELECT
    'products — product_category_name',
    COUNT(*),
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM products;

-- ============================================================
-- QUERY 3: Risk tier threshold analysis
-- Validates that thresholds in mart_seller_risk are grounded
-- in the actual distribution of seller performance metrics
-- Run against int_seller_metrics (delivered_orders >= 10)
-- ============================================================

SELECT
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_review_score)::numeric, 2) AS p25_review,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_review_score)::numeric, 2) AS p50_review,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_review_score)::numeric, 2) AS p75_review,

    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY late_delivery_rate)::numeric, 4) AS p25_late,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY late_delivery_rate)::numeric, 4) AS p50_late,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY late_delivery_rate)::numeric, 4) AS p75_late
FROM int_seller_metrics
WHERE delivered_orders >= 10;
