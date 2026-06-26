-- ============================================================
-- Assigns seller risk tiers and quantifies GMV exposure
-- Combines operational quality, customer satisfaction,
-- and seller revenue concentration
-- One row per seller
-- ============================================================

CREATE OR REPLACE VIEW mart_seller_risk AS

WITH scored AS (
    SELECT
        seller_id,
        all_orders,
        delivered_orders,
        cancellation_rate,
        late_delivery_count,
        late_delivery_rate,
        avg_review_score,
        low_rating_pct,
        COALESCE(total_revenue, 0) AS total_revenue,

        CASE
            WHEN delivered_orders < 10                                        THEN 'WATCH'
            WHEN avg_review_score < 3.0
              OR (late_delivery_rate > 0.30 AND avg_review_score < 3.5)      THEN 'HIGH'
            WHEN late_delivery_rate > 0.10 OR avg_review_score < 3.8         THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_tier

    FROM int_seller_metrics
)

SELECT
    seller_id,
    all_orders,
    delivered_orders,
    cancellation_rate,
    late_delivery_count,
    late_delivery_rate,
    avg_review_score,
    low_rating_pct,
    total_revenue,
    risk_tier,

    ROUND(100.0 * COALESCE(total_revenue, 0) / SUM(COALESCE(total_revenue, 0)) OVER (), 2) AS revenue_share_pct,

    CASE WHEN risk_tier = 'HIGH' THEN COALESCE(total_revenue, 0) END AS revenue_at_risk,

    RANK() OVER (
        ORDER BY
            CASE risk_tier WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'WATCH' THEN 3 ELSE 4 END,
            avg_review_score   ASC,
            late_delivery_rate DESC,
            total_revenue      DESC
    ) AS risk_rank

FROM scored;

-- ============================================================
-- Validation
-- ============================================================

-- Grain + completeness
-- SELECT 'grain' AS check_type, COUNT(*) AS rows, COUNT(DISTINCT seller_id) AS unique_sellers
-- FROM mart_seller_risk;

-- Revenue reconciliation
-- SELECT 'revenue_reconciliation'             AS check_type,
--        ROUND(SUM(total_revenue), 0)         AS mart_revenue,
--        (SELECT ROUND(SUM(total_revenue), 0) FROM int_seller_metrics) AS source_revenue
-- FROM mart_seller_risk;

-- Missing risk tiers
-- SELECT 'missing_tiers' AS check_type, COUNT(*) AS null_tiers
-- FROM mart_seller_risk
-- WHERE risk_tier IS NULL;

-- Revenue share integrity
-- SELECT 'revenue_share' AS check_type, ROUND(SUM(revenue_share_pct), 2) AS total_share
-- FROM mart_seller_risk;

-- Tier distribution
-- SELECT 'tier_distribution' AS check_type,
--        risk_tier,
--        COUNT(*) AS sellers,
--        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
-- FROM mart_seller_risk
-- GROUP BY risk_tier
-- ORDER BY sellers DESC;
