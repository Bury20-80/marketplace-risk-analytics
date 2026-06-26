-- ============================================================
-- Filters to delivered orders with known delivery date
-- Standardizes timestamps for downstream date arithmetic
-- Adds month grain column for time-series aggregation
-- ============================================================

CREATE OR REPLACE VIEW stg_orders AS

SELECT
    order_id,
    customer_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_year_month
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM stg_orders;
-- SELECT COUNT(*) FROM orders WHERE order_status = 'delivered';
-- Difference of 8: stg_orders excludes rows with NULL delivery date
