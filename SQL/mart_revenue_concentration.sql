-- ============================================================
-- Measures seller GMV concentration across the marketplace
-- Produces Pareto metrics for seller contribution analysis
-- One row per seller
-- ============================================================

CREATE OR REPLACE VIEW mart_revenue_concentration AS

SELECT
    seller_id,
    total_revenue,

    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,

    ROUND(
        100 * SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(total_revenue) OVER (),
        2
    ) AS cumulative_revenue_pct,

    ROUND(
        100.0 * RANK() OVER (ORDER BY total_revenue DESC) / COUNT(*) OVER (),
        2
    ) AS cumulative_seller_pct

FROM int_seller_metrics;

-- ============================================================
-- Validation
-- ============================================================

-- Grain
-- SELECT 'grain' AS check_type, COUNT(*) AS rows, COUNT(DISTINCT seller_id) AS unique_sellers
-- FROM mart_revenue_concentration;

-- Pareto completion
-- SELECT 'pareto_completion'         AS check_type,
--        MAX(cumulative_revenue_pct) AS max_revenue_pct,
--        MAX(cumulative_seller_pct)  AS max_seller_pct
-- FROM mart_revenue_concentration;

-- Null checks
-- SELECT 'null_check' AS check_type, COUNT(*) AS null_rows
-- FROM mart_revenue_concentration
-- WHERE total_revenue IS NULL
--    OR cumulative_revenue_pct IS NULL
--    OR cumulative_seller_pct IS NULL;

-- Revenue reconciliation
-- SELECT 'revenue_reconciliation'             AS check_type,
--        ROUND(SUM(total_revenue), 0)         AS mart_revenue,
--        (SELECT ROUND(SUM(total_revenue), 0) FROM int_seller_metrics) AS source_revenue
-- FROM mart_revenue_concentration;
