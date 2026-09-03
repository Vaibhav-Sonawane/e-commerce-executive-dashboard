-- 01_database_setup.sql

CREATE EXTENSION IF NOT EXISTS pg_trgm;

DROP TABLE IF EXISTS staging_transactions;

CREATE TABLE staging_transactions (
    invoice_number VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(12,4),
    customer_id VARCHAR(20),
    country VARCHAR(100),
    transaction_date DATE,
    transaction_month INTEGER,
    transaction_year INTEGER,
    transaction_time TIME,
    gross_revenue NUMERIC(14,4),
    return_value NUMERIC(14,4),
    net_revenue NUMERIC(14,4),
    transaction_status VARCHAR(20)
);