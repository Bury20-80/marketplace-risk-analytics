-- ============================================================
-- Standardizes orders without filtering out any order status
-- Keeps timestamps required for delivery and cancellation metrics
-- Adds a monthly field while preserving one row per order
-- ============================================================

CREATE OR REPLACE VIEW stg_orders AS

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_year_month
FROM orders;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) AS rows, COUNT(DISTINCT order_id) AS unique_orders
-- FROM stg_orders;

-- SELECT order_status, COUNT(*) AS orders
-- FROM stg_orders
-- GROUP BY order_status
-- ORDER BY orders DESC;

-- ============================================================
