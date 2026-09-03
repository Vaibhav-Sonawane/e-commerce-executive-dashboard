-- 06_revenue_analysis.sql

-- A. Headline totals

SELECT
    SUM(gross_revenue) AS gross_revenue,
    SUM(return_value) AS returns,
    SUM(net_revenue) AS net_revenue,
    COUNT(DISTINCT invoice_number) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(CASE WHEN is_cancelled = FALSE THEN quantity ELSE 0 END) AS units_sold,
    ROUND(SUM(net_revenue) / NULLIF(COUNT(DISTINCT invoice_number), 0), 2) AS aov,
    ROUND(SUM(net_revenue) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS revenue_per_customer,
    ROUND(COUNT(DISTINCT invoice_number)::NUMERIC / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS orders_per_customer
FROM fact_sales;

-- B. Monthly revenue, orders, customers

DROP TABLE IF EXISTS monthly_revenue;

CREATE TABLE monthly_revenue AS
SELECT
    d.year,
    d.month,
    d.year_month,
    SUM(f.net_revenue) AS net_revenue,
    COUNT(DISTINCT f.invoice_number) AS orders,
    COUNT(DISTINCT f.customer_id) AS customers,
    ROUND(SUM(f.net_revenue) / NULLIF(COUNT(DISTINCT f.invoice_number), 0), 2) AS aov
FROM fact_sales f
JOIN dim_date d ON f.transaction_date = d.date
GROUP BY d.year, d.month, d.year_month
ORDER BY d.year, d.month;

SELECT * FROM monthly_revenue ORDER BY year, month;

-- C. MoM and YoY growth

SELECT
    year_month,
    net_revenue,
    LAG(net_revenue, 1)  OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        (net_revenue - LAG(net_revenue, 1) OVER (ORDER BY year, month))
        / NULLIF(LAG(net_revenue, 1) OVER (ORDER BY year, month), 0) * 100, 2
    ) AS mom_growth_pct,
    LAG(net_revenue, 12) OVER (ORDER BY year, month) AS prev_year_revenue,
    ROUND(
        (net_revenue - LAG(net_revenue, 12) OVER (ORDER BY year, month))
        / NULLIF(LAG(net_revenue, 12) OVER (ORDER BY year, month), 0) * 100, 2
    ) AS yoy_growth_pct
FROM monthly_revenue
ORDER BY year, month;

-- D. Revenue decomposition: Revenue = Customers x Orders/Customer x AOV

SELECT
    year_month,
    customers,
    ROUND(orders::NUMERIC / NULLIF(customers, 0), 2) AS orders_per_customer,
    aov,
    net_revenue
FROM monthly_revenue
ORDER BY year, month;