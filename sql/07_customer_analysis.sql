-- 07_customer_analysis.sql

-- A. Customer level summary table

DROP TABLE IF EXISTS customer_summary;

CREATE TABLE customer_summary AS
SELECT
    customer_id,
    SUM(net_revenue) AS total_net_revenue,
    COUNT(DISTINCT invoice_number) AS distinct_orders,
    SUM(CASE WHEN is_cancelled = FALSE THEN quantity ELSE 0 END) AS total_units,
    ROUND(SUM(net_revenue) / NULLIF(COUNT(DISTINCT invoice_number), 0), 2) AS aov,
    MIN(transaction_date) AS first_purchase_date,
    MAX(transaction_date) AS last_purchase_date
FROM fact_sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

CREATE INDEX idx_customer_summary_id ON customer_summary(customer_id);

SELECT * FROM customer_summary ORDER BY total_net_revenue DESC LIMIT 20;

-- B. Customer concentration

WITH ranked AS (
    SELECT
        customer_id,
        total_net_revenue,
        NTILE(100) OVER (ORDER BY total_net_revenue DESC) AS percentile_bucket
    FROM customer_summary
),
totals AS (
    SELECT SUM(total_net_revenue) AS grand_total FROM customer_summary
)
SELECT
    'Top 1%'  AS segment, ROUND(SUM(r.total_net_revenue) / t.grand_total * 100, 2) AS pct_of_revenue
FROM ranked r, totals t WHERE r.percentile_bucket <= 1
GROUP BY t.grand_total

UNION ALL

SELECT
    'Top 5%', ROUND(SUM(r.total_net_revenue) / t.grand_total * 100, 2)
FROM ranked r, totals t WHERE r.percentile_bucket <= 5
GROUP BY t.grand_total

UNION ALL

SELECT
    'Top 10%', ROUND(SUM(r.total_net_revenue) / t.grand_total * 100, 2)
FROM ranked r, totals t WHERE r.percentile_bucket <= 10
GROUP BY t.grand_total

UNION ALL

SELECT
    'Top 20%', ROUND(SUM(r.total_net_revenue) / t.grand_total * 100, 2)
FROM ranked r, totals t WHERE r.percentile_bucket <= 20
GROUP BY t.grand_total;

-- C. Quick distribution check 

SELECT
    COUNT(*) AS total_customers,
    ROUND(AVG(total_net_revenue), 2) AS avg_revenue_per_customer,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_net_revenue)::NUMERIC, 2) AS median_revenue_per_customer,
    ROUND(MAX(total_net_revenue), 2) AS max_revenue_single_customer
FROM customer_summary;

