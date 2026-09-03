-- 02_raw_load.sql

TRUNCATE TABLE staging_transactions;

SELECT COUNT(*) AS staging_row_count FROM staging_transactions;

-- it needs to run specialised psql for clean copy
-- cmd >> psql -U postgres -d database_name
-- database_name=# \copy staging_transactions FROM 'data/processed/online_retail_ii_clean.csv' WITH (FORMAT csv, HEADER true, NULL '');

SELECT COUNT(*) AS staging_row_count FROM staging_transactions;

SELECT
    COUNT(*) FILTER (WHERE invoice_number IS NULL) AS null_invoice,
    COUNT(*) FILTER (WHERE stock_code IS NULL) AS null_stock_code,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE description IS NULL) AS null_description,
    COUNT(*) FILTER (WHERE transaction_date IS NULL) AS null_transaction_date
FROM staging_transactions;
