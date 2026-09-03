-- 10_product_analysis.sql

DROP TABLE IF EXISTS product_summary;

CREATE TABLE product_summary AS
SELECT
    f.stock_code,
    p.description,
    SUM(f.net_revenue) AS revenue,
    SUM(CASE WHEN f.is_cancelled = FALSE THEN f.quantity ELSE 0 END) AS units_sold,
    COUNT(DISTINCT f.invoice_number) AS orders_containing_product,
    COUNT(DISTINCT f.customer_id) AS unique_customers_reached
FROM fact_sales f
JOIN dim_product p ON f.stock_code = p.stock_code
WHERE p.is_admin_code = FALSE
GROUP BY f.stock_code, p.description;

-- Top products by revenue
SELECT * FROM product_summary ORDER BY revenue DESC LIMIT 20;

-- Top products by units sold
SELECT * FROM product_summary ORDER BY units_sold DESC LIMIT 20;

-- Top products by customer reach
SELECT * FROM product_summary ORDER BY unique_customers_reached DESC LIMIT 20;
