-- 08_rfm_analysis.sql

-- A. Reference date

DROP TABLE IF EXISTS reference_date;

CREATE TABLE reference_date AS
SELECT (MAX(transaction_date) + INTERVAL '1 day')::DATE AS ref_date
FROM fact_sales;

SELECT * FROM reference_date;

-- B. Raw R/F/M values per customer

DROP TABLE IF EXISTS rfm_values;

CREATE TABLE rfm_values AS
SELECT
    cs.customer_id,
    (rd.ref_date - cs.last_purchase_date) AS recency_days,
    cs.distinct_orders AS frequency,
    cs.total_net_revenue AS monetary
FROM customer_summary cs
CROSS JOIN reference_date rd;

SELECT * FROM rfm_values ORDER BY monetary DESC LIMIT 20;

-- C. RFM scoring

DROP TABLE IF EXISTS rfm_scores;

CREATE TABLE rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    (6 - NTILE(5) OVER (ORDER BY recency_days)) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM rfm_values;

-- D. Segment labeling from R/F/M scores

DROP TABLE IF EXISTS rfm_segments;

CREATE TABLE rfm_segments AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score <= 3 AND m_score <= 3 THEN 'Potential Loyalists'
        WHEN r_score = 3 AND f_score <= 2 THEN 'Need Attention'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Need Attention'
    END AS rfm_segment
FROM rfm_scores;

SELECT rfm_segment, COUNT(*) AS customers, SUM(monetary) AS segment_revenue
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY segment_revenue DESC;

-- E. At-Risk specific figures

SELECT
    COUNT(*) AS at_risk_customers,
    SUM(monetary) AS at_risk_historical_revenue,
    ROUND(SUM(monetary) / (SELECT SUM(monetary) FROM rfm_segments) * 100, 2) AS pct_of_total_revenue
FROM rfm_segments
WHERE rfm_segment = 'At Risk';



