-- ============================================================
-- Standardizes seller dimension
-- Limits columns to those used in analysis
-- Reserved for future geographic enrichment
-- ============================================================

CREATE OR REPLACE VIEW stg_sellers AS

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM sellers;

-- ============================================================
-- Validation
-- ============================================================

-- SELECT COUNT(*) FROM stg_sellers;
