-- ============================================================
-- Assigns seller risk tiers using attributable quality metrics
-- Prevents sellers with insufficient quality history receiving LOW
-- Quantifies delivered-order GMV exposure for every risk tier
-- ============================================================

CREATE OR REPLACE VIEW mart_seller_risk AS

WITH scored AS (
    SELECT
        seller_id,
        all_orders,
        delivered_orders,
        cancelled_orders,
        cancellation_rate,
        delivery_quality_orders,
        review_quality_orders,
        late_delivery_count,
        late_delivery_rate,
        avg_review_score,
        low_rating_pct,
        seller_gmv,
        CASE
            WHEN delivery_quality_orders < 10
              OR review_quality_orders < 10
              OR avg_review_score IS NULL
              OR late_delivery_rate IS NULL
                THEN 'WATCH'
            WHEN avg_review_score < 3.0
              OR (
                    late_delivery_rate > 0.30
                    AND avg_review_score < 3.5
                 )
                THEN 'HIGH'
            WHEN late_delivery_rate > 0.10
              OR avg_review_score < 3.8
                THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_tier
    FROM int_seller_metrics
)

SELECT
    seller_id,
    all_orders,
    delivered_orders,
    cancelled_orders,
    cancellation_rate,
    delivery_quality_orders,
    review_quality_orders,
    late_delivery_count,
    late_delivery_rate,
    avg_review_score,
    low_rating_pct,
    seller_gmv,
    risk_tier,
    ROUND(
        100.0 * seller_gmv / NULLIF(SUM(seller_gmv) OVER (), 0),
        2
    ) AS gmv_share_pct,
    CASE
        WHEN risk_tier = 'HIGH' THEN seller_gmv
        ELSE 0
    END AS high_risk_gmv,
    ROW_NUMBER() OVER (
        ORDER BY
            CASE risk_tier
                WHEN 'HIGH' THEN 1
                WHEN 'MEDIUM' THEN 2
                WHEN 'WATCH' THEN 3
                ELSE 4
            END,
            avg_review_score ASC NULLS LAST,
            late_delivery_rate DESC NULLS LAST,
            seller_gmv DESC,
            seller_id
    ) AS risk_rank
FROM scored;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT risk_tier, COUNT(*) AS sellers, ROUND(SUM(seller_gmv), 2) AS gmv
-- FROM mart_seller_risk
-- GROUP BY risk_tier
-- ORDER BY risk_tier;

-- SELECT COUNT(*) AS sellers_missing_tier
-- FROM mart_seller_risk
-- WHERE risk_tier IS NULL;

-- SELECT ROUND(SUM(high_risk_gmv), 2) AS high_risk_gmv
-- FROM mart_seller_risk;

-- ============================================================
