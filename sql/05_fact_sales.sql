-- 05_fact_sales.sql

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales AS
SELECT
    invoice_number,
    stock_code,
    customer_id,
    transaction_date,
    transaction_time,
    country,
    quantity,
    unit_price,
    is_cancelled,
	python_gross_revenue AS gross_revenue,
    python_return_value AS return_value,
    python_net_revenue AS net_revenue,
    transaction_status
FROM clean_transactions;

ALTER TABLE fact_sales
    ADD CONSTRAINT fk_fact_product FOREIGN KEY (stock_code) REFERENCES dim_product(stock_code),
    ADD CONSTRAINT fk_fact_country FOREIGN KEY (country) REFERENCES dim_country(country),
    ADD CONSTRAINT fk_fact_date FOREIGN KEY (transaction_date) REFERENCES dim_date(date);

CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_product ON fact_sales(stock_code);
CREATE INDEX idx_fact_date ON fact_sales(transaction_date);
CREATE INDEX idx_fact_country ON fact_sales(country);
CREATE INDEX idx_fact_invoice ON fact_sales(invoice_number);

-- RECONCILIATION GATE

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice_number) AS distinct_orders,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(DISTINCT stock_code) AS distinct_products,
    SUM(net_revenue) AS total_net_revenue,
    MIN(transaction_date) AS min_date,
    MAX(transaction_date) AS max_date
FROM fact_sales;



