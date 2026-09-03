-- 12_geographic_analysis.sql

DROP TABLE IF EXISTS geographic_summary;

CREATE TABLE geographic_summary AS

SELECT
    country,
    SUM(net_revenue) AS revenue,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT invoice_number) AS orders,
    ROUND(SUM(net_revenue) / NULLIF(COUNT(DISTINCT invoice_number), 0), 2) AS aov,
    ROUND(SUM(net_revenue) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS revenue_per_customer
FROM fact_sales
GROUP BY country;

-- Top countries by total revenue
SELECT * FROM geographic_summary ORDER BY revenue DESC LIMIT 20;

-- Top countries by AOV
SELECT * FROM geographic_summary ORDER BY aov DESC LIMIT 20;

-- Top countries by revenue per customer
SELECT * FROM geographic_summary ORDER BY revenue_per_customer DESC LIMIT 20;

-- (Many customers, low value per customer) markets
SELECT
    country,
    customers,
    revenue_per_customer,
    revenue
FROM geographic_summary
WHERE customers >= 10
ORDER BY customers DESC, revenue_per_customer ASC
LIMIT 20;


SELECT country, customers, orders
FROM geographic_summary
ORDER BY customers ASC
LIMIT 15;
