-- 09_retention_analysis.sql

-- A. First purchase month per customer

DROP TABLE IF EXISTS customer_cohort;

CREATE TABLE customer_cohort AS
SELECT
    customer_id,
    DATE_TRUNC('month', first_purchase_date)::DATE AS cohort_month
FROM customer_summary;

-- B. Customer activity by month

DROP TABLE IF EXISTS customer_activity_by_month;

CREATE TABLE customer_activity_by_month AS
SELECT DISTINCT
    f.customer_id,
    cc.cohort_month,
    DATE_TRUNC('month', f.transaction_date)::DATE AS activity_month,
    (
        (EXTRACT(YEAR FROM f.transaction_date) - EXTRACT(YEAR FROM cc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM f.transaction_date) - EXTRACT(MONTH FROM cc.cohort_month))
    )::INTEGER AS months_since_first_purchase
FROM fact_sales f
JOIN customer_cohort cc ON f.customer_id = cc.customer_id
WHERE f.customer_id IS NOT NULL;

-- C. Cohort retention table

DROP TABLE IF EXISTS cohort_retention;

CREATE TABLE cohort_retention AS
SELECT
    cohort_month,
    months_since_first_purchase,
    COUNT(DISTINCT customer_id) AS active_customers
FROM customer_activity_by_month
WHERE months_since_first_purchase BETWEEN 0 AND 12   -- cap at 12 months out; extend if useful
GROUP BY cohort_month, months_since_first_purchase
ORDER BY cohort_month, months_since_first_purchase;

SELECT
    cr.cohort_month,
    cr.months_since_first_purchase,
    cr.active_customers,
    cohort_size.customers AS cohort_size,
    ROUND(cr.active_customers::NUMERIC / NULLIF(cohort_size.customers, 0) * 100, 2) AS retention_pct
FROM cohort_retention cr
JOIN (
    SELECT cohort_month, active_customers AS customers
    FROM cohort_retention
    WHERE months_since_first_purchase = 0
) cohort_size ON cr.cohort_month = cohort_size.cohort_month
ORDER BY cr.cohort_month, cr.months_since_first_purchase;

-- D. New vs. repeat customers per month
SELECT
    activity_month,
    COUNT(DISTINCT customer_id) FILTER (WHERE months_since_first_purchase = 0) AS new_customers,
    COUNT(DISTINCT customer_id) FILTER (WHERE months_since_first_purchase > 0) AS repeat_customers
FROM customer_activity_by_month
GROUP BY activity_month
ORDER BY activity_month;