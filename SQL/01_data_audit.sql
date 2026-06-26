-- ============================================================
-- OLIST E-COMMERCE — PHASE 1: DATA AUDIT & BUSINESS EXPLORATION
-- Run AFTER all CSVs are imported
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
-- QUERY 3: ORDER STATUS FUNNEL
-- Business question: "How many orders actually complete successfully?"
-- Why it matters: Conversion/completion rate is a core ops metric.
-- ============================================================

SELECT
    order_status,
    COUNT(*)                                                AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 3)     AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- ============================================================
-- QUERY 4: MONTHLY REVENUE TREND
-- Business question: "Is the business growing? When does it peak?"
-- Skills shown: JOIN, DATE_TRUNC, window functions, filtering
-- ============================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)        AS order_month,
    COUNT(DISTINCT o.order_id)                             AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)                       AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2)               AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2)    AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                       AS avg_item_price,

    -- Month-over-month revenue growth
    ROUND(
        (SUM(oi.price + oi.freight_value) - LAG(SUM(oi.price + oi.freight_value))
            OVER (ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp)))
        / NULLIF(LAG(SUM(oi.price + oi.freight_value))
            OVER (ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp)), 0) * 100, 2
    ) AS mom_growth_pct

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY order_month;
-- ============================================================
-- QUERY 5: TOP 15 PRODUCT CATEGORIES BY REVENUE
-- Business question: "Where does most of our money come from?"
-- Skills shown: 3-table JOIN, COALESCE for nulls, % share via window function
-- ============================================================

SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'Unknown')                                     AS category_en,
    COUNT(DISTINCT oi.order_id)                             AS total_orders,
    COUNT(oi.order_item_id)                                 AS total_units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2)                       AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                       AS avg_unit_price,
    ROUND(
        SUM(oi.price) * 100.0 / SUM(SUM(oi.price)) OVER ()
    , 2)                                                    AS revenue_share_pct,
    ROUND(AVG(r.avg_review_score)::NUMERIC, 2)             AS avg_review_score

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
LEFT JOIN stg_reviews r
    ON o.order_id = r.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown')
ORDER BY total_revenue DESC
LIMIT 15;


-- ============================================================
-- QUERY 6: DELIVERY PERFORMANCE BY STATE
-- Business question: "Which regions have logistics problems?"
-- Skills shown: EXTRACT(EPOCH), CASE statements, HAVING, multi-join
-- Output: Will become a map visual in Power BI
-- ============================================================

SELECT
    c.customer_state,
    COUNT(o.order_id)                                       AS total_delivered_orders,

    ROUND(AVG(
        EXTRACT(EPOCH FROM
            (o.order_delivered_customer_date - o.order_purchase_timestamp)
        ) / 86400
    )::NUMERIC, 1)                                          AS avg_total_days_to_deliver,

    ROUND(AVG(
        EXTRACT(EPOCH FROM
            (o.order_delivered_customer_date - o.order_delivered_carrier_date)
        ) / 86400
    )::NUMERIC, 1)                                          AS avg_days_with_carrier,

    -- Positive = delivered EARLY, Negative = delivered LATE
    ROUND(AVG(
        EXTRACT(EPOCH FROM
            (o.order_estimated_delivery_date - o.order_delivered_customer_date)
        ) / 86400
    )::NUMERIC, 1)                                          AS avg_days_vs_estimate,

    ROUND(
        SUM(CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*), 1
    )                                                       AS on_time_pct,

    ROUND(AVG(rev.review_score), 2)               AS avg_review_score

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN order_reviews rev
    ON o.order_id = rev.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND o.order_delivered_carrier_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(o.order_id) >= 50   -- minimum sample size per state
ORDER BY avg_total_days_to_deliver DESC;

-- ============================================================
-- QUERY 7: Risk tier threshold analysis
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