-- ============================================================
-- Loads the raw CSV files required by the project
-- Uses psql \copy so files are read from the client machine
-- Requires paths below to be replaced with local absolute paths
-- ============================================================

-- Run schema.sql first on a fresh database.
-- This script is intended for psql.
-- In DBeaver, use Import Data for the same seven CSV files.

\copy customers FROM '/absolute/path/to/data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy products FROM '/absolute/path/to/data/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy sellers FROM '/absolute/path/to/data/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy product_category_translation FROM '/absolute/path/to/data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy orders FROM '/absolute/path/to/data/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy order_items FROM '/absolute/path/to/data/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy order_reviews FROM '/absolute/path/to/data/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ============================================================
-- Validation
-- ============================================================

-- SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
-- UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
-- UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
-- UNION ALL SELECT 'orders', COUNT(*) FROM orders
-- UNION ALL SELECT 'product_category_translation', COUNT(*) FROM product_category_translation
-- UNION ALL SELECT 'products', COUNT(*) FROM products
-- UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
-- ORDER BY table_name;

-- ============================================================
