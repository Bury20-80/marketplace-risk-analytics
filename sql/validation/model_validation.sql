-- ============================================================
-- Validates analytical grains and cross-model reconciliations
-- Detects fan-out, missing seller attribution and GMV duplication
-- Run after all staging, intermediate and mart views are rebuilt
-- ============================================================

SELECT
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM int_order_facts;

SELECT
    order_id,
    seller_id,
    COUNT(*) AS rows
FROM int_seller_order_facts
GROUP BY order_id, seller_id
HAVING COUNT(*) > 1;

SELECT
    (
        SELECT ROUND(SUM(order_gmv), 2)
        FROM int_order_facts
        WHERE is_delivered_eligible
    ) AS order_fact_gmv,
    (
        SELECT ROUND(SUM(seller_order_gmv), 2)
        FROM int_seller_order_facts
        WHERE is_delivered_eligible
    ) AS seller_order_fact_gmv,
    (
        SELECT ROUND(SUM(seller_gmv), 2)
        FROM int_seller_metrics
    ) AS seller_metric_gmv;

SELECT
    (SELECT COUNT(*) FROM sellers) AS seller_dimension_rows,
    (SELECT COUNT(*) FROM int_seller_metrics) AS seller_metric_rows;

SELECT
    COUNT(*) FILTER (
        WHERE is_delivered_eligible
          AND is_single_seller_order
          AND avg_review_score IS NULL
    ) AS single_seller_delivered_orders_without_review
FROM int_seller_order_facts;

SELECT
    risk_tier,
    COUNT(*) AS sellers,
    ROUND(SUM(seller_gmv), 2) AS seller_gmv,
    ROUND(
        100.0 * SUM(seller_gmv)
        / NULLIF(SUM(SUM(seller_gmv)) OVER (), 0),
        2
    ) AS gmv_share_pct
FROM mart_seller_risk
GROUP BY risk_tier
ORDER BY risk_tier;

SELECT
    MAX(cumulative_gmv_pct) AS max_cumulative_gmv_pct,
    MAX(cumulative_seller_pct) AS max_cumulative_seller_pct
FROM mart_revenue_concentration;

SELECT
    (
        SELECT ROUND(SUM(category_risk_gmv), 2)
        FROM mart_category_risk
    ) AS category_gmv,
    (
        SELECT ROUND(SUM(order_gmv), 2)
        FROM int_order_facts
        WHERE is_delivered_eligible
    ) AS order_fact_gmv;

SELECT
    ROUND(
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_review_score)::NUMERIC,
        2
    ) AS p25_review,
    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_review_score)::NUMERIC,
        2
    ) AS p50_review,
    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_review_score)::NUMERIC,
        2
    ) AS p75_review,
    ROUND(
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY late_delivery_rate)::NUMERIC,
        4
    ) AS p25_late,
    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY late_delivery_rate)::NUMERIC,
        4
    ) AS p50_late,
    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY late_delivery_rate)::NUMERIC,
        4
    ) AS p75_late
FROM int_seller_metrics
WHERE delivery_quality_orders >= 10
  AND review_quality_orders >= 10;

-- ============================================================
-- Expected result
-- Grain checks return zero duplicates and all GMV totals reconcile
-- Review NULLs remain excluded from review-quality denominators
-- ============================================================
