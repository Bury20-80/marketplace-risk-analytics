-- ============================================================
-- Aggregates seller risk across product categories
-- Quantifies GMV exposure by category × risk tier
-- One row per category × risk tier
-- ============================================================

CREATE OR REPLACE VIEW mart_category_risk AS

WITH seller_category AS (
    SELECT
        f.product_category_en  AS category_en,
        r.risk_tier,
        f.seller_id,
        SUM(f.total_revenue)   AS total_revenue
    FROM int_order_facts f
    JOIN mart_seller_risk r ON f.seller_id = r.seller_id
    GROUP BY f.product_category_en, r.risk_tier, f.seller_id
),

agg AS (
    SELECT
        category_en,
        risk_tier,
        COUNT(DISTINCT seller_id) AS seller_count,
        SUM(total_revenue)        AS total_revenue
    FROM seller_category
    GROUP BY category_en, risk_tier
)

SELECT
    category_en,
    risk_tier,
    seller_count,
    ROUND(total_revenue, 0)                                                          AS total_revenue,
    ROUND(SUM(total_revenue) OVER (PARTITION BY category_en), 0)                    AS category_total_revenue,
    ROUND(100 * total_revenue / SUM(total_revenue) OVER (PARTITION BY category_en), 2) AS pct_of_category_revenue
FROM agg;

-- ============================================================
-- Validation
-- ============================================================

-- Empty categories
-- SELECT 'empty_categories' AS check_type, COUNT(*)
-- FROM mart_category_risk
-- WHERE category_en IS NULL OR TRIM(category_en) = '';

-- Revenue share sums to 100% per category
-- SELECT 'revenue_integrity' AS check_type, COUNT(*) AS invalid_categories
-- FROM (
--     SELECT category_en, ROUND(SUM(pct_of_category_revenue), 2) AS total_pct
--     FROM mart_category_risk
--     GROUP BY category_en
--     HAVING ABS(SUM(pct_of_category_revenue) - 100) > 0.01
-- ) x;

-- Revenue reconciliation
-- SELECT 'revenue_reconciliation'             AS check_type,
--        ROUND(SUM(total_revenue), 0)         AS mart_revenue,
--        (SELECT ROUND(SUM(total_revenue), 0) FROM int_order_facts) AS source_revenue
-- FROM mart_category_risk;

-- Coverage
-- SELECT 'grain' AS check_type, COUNT(*) AS rows, COUNT(DISTINCT category_en) AS categories
-- FROM mart_category_risk;
