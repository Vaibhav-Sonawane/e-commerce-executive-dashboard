-- 03_clean_transactions.sql

DROP TABLE IF EXISTS clean_transactions;

CREATE TABLE clean_transactions AS
SELECT
    invoice_number,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    NULLIF(customer_id, '')::NUMERIC::INTEGER AS customer_id,
    country,
    transaction_date,
    transaction_month,
    transaction_year,
    transaction_time,
    transaction_status,

    (transaction_status = 'Cancelled') AS is_cancelled,

    gross_revenue AS python_gross_revenue,
    return_value  AS python_return_value,
    net_revenue   AS python_net_revenue,

    CASE WHEN quantity >= 0 THEN ROUND(quantity * unit_price, 4) ELSE 0 END AS sql_gross_revenue,
    CASE WHEN quantity < 0  THEN ROUND(ABS(quantity) * unit_price, 4) ELSE 0 END AS sql_return_value,
    CASE
        WHEN quantity >= 0 THEN ROUND(quantity * unit_price, 4)
        ELSE ROUND(quantity * unit_price, 4)
    END AS sql_net_revenue

FROM staging_transactions;

-- PART A: Duplicates Check

SELECT invoice_number, stock_code, description, quantity, invoice_date, unit_price, customer_id, country, COUNT(*)
FROM clean_transactions
GROUP BY invoice_number, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
HAVING COUNT(*) > 1;

-- PART B: Revenue Check

SELECT
    'python_side' AS source,
    SUM(python_gross_revenue) AS total_gross_revenue,
    SUM(python_return_value) AS total_return_value,
    SUM(python_net_revenue) AS total_net_revenue
FROM clean_transactions

UNION ALL

SELECT
    'sql_side',
    SUM(sql_gross_revenue),
    SUM(sql_return_value),
    SUM(sql_net_revenue)
FROM clean_transactions;

-- PART C: Row/Order/customer count check
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice_number) AS distinct_orders,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(DISTINCT stock_code) AS distinct_products
FROM clean_transactions;
