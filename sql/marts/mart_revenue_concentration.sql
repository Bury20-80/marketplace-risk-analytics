-- ============================================================
-- Measures delivered-order GMV concentration across sellers
-- Uses deterministic ROW_NUMBER ordering for Pareto calculations
-- Produces one row per seller with cumulative seller and GMV shares
-- ============================================================

CREATE OR REPLACE VIEW mart_revenue_concentration AS

WITH ranked AS (
    SELECT
        seller_id,
        seller_gmv,
        ROW_NUMBER() OVER (
            ORDER BY seller_gmv DESC, seller_id
        ) AS revenue_rank,
        COUNT(*) OVER () AS seller_count,
        SUM(seller_gmv) OVER () AS total_gmv
    FROM int_seller_metrics
),

cumulative AS (
    SELECT
        seller_id,
        seller_gmv,
        revenue_rank,
        seller_count,
        total_gmv,
        SUM(seller_gmv) OVER (
            ORDER BY revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_gmv
    FROM ranked
)

SELECT
    seller_id,
    seller_gmv,
    revenue_rank,
    ROUND(
        100.0 * cumulative_gmv / NULLIF(total_gmv, 0),
        2
    ) AS cumulative_gmv_pct,
    ROUND(
        100.0 * revenue_rank / NULLIF(seller_count, 0),
        2
    ) AS cumulative_seller_pct
FROM cumulative;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT
--     COUNT(*) AS rows,
--     COUNT(DISTINCT seller_id) AS unique_sellers,
--     MAX(cumulative_gmv_pct) AS max_cumulative_gmv_pct,
--     MAX(cumulative_seller_pct) AS max_cumulative_seller_pct
-- FROM mart_revenue_concentration;

-- SELECT *
-- FROM mart_revenue_concentration
-- WHERE cumulative_gmv_pct >= 80
-- ORDER BY revenue_rank
-- LIMIT 1;

-- ============================================================
