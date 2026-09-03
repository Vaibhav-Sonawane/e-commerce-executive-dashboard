-- 11_market_basket.sql

-- A. Valid baskets: one row per (invoice, distinct product), cancelled

DROP TABLE IF EXISTS basket_items;

CREATE TABLE basket_items AS
SELECT DISTINCT
    f.invoice_number,
    f.stock_code
FROM fact_sales f
JOIN dim_product p ON f.stock_code = p.stock_code
WHERE f.transaction_status = 'Completed'
  AND p.is_admin_code = FALSE;

CREATE INDEX idx_basket_invoice ON basket_items(invoice_number);
CREATE INDEX idx_basket_product ON basket_items(stock_code);

-- Total valid baskets — denominator for Support.
DROP TABLE IF EXISTS total_baskets;

CREATE TABLE total_baskets AS
SELECT COUNT(DISTINCT invoice_number) AS total_valid_baskets FROM basket_items;

-- B. Product-level baseline purchase frequency

DROP TABLE IF EXISTS product_basket_counts;

CREATE TABLE product_basket_counts AS
SELECT
    stock_code,
    COUNT(DISTINCT invoice_number) AS baskets_containing_product
FROM basket_items
GROUP BY stock_code;

-- C. Pair counts via SELF-JOIN.

DROP TABLE IF EXISTS pair_counts;

CREATE TABLE pair_counts AS
SELECT
    a.stock_code AS product_a,
    b.stock_code AS product_b,
    COUNT(DISTINCT a.invoice_number) AS pair_orders
FROM basket_items a
JOIN basket_items b
    ON a.invoice_number = b.invoice_number
    AND a.stock_code < b.stock_code 
GROUP BY a.stock_code, b.stock_code;

CREATE INDEX idx_pair_a ON pair_counts(product_a);
CREATE INDEX idx_pair_b ON pair_counts(product_b);

-- D. Minimum threshold

DROP TABLE IF EXISTS pair_counts_filtered;

CREATE TABLE pair_counts_filtered AS
SELECT *
FROM pair_counts
WHERE pair_orders >= 10;

-- E. Final metrics: Support, directional Confidence (both ways), Lift.

DROP TABLE IF EXISTS market_basket_results;

CREATE TABLE market_basket_results AS
SELECT
    pc.product_a,
    pa.description AS product_a_description,
    pc.product_b,
    pb.description AS product_b_description,
    pc.pair_orders,

    -- Support: share of ALL valid baskets containing this pair
    ROUND(pc.pair_orders::NUMERIC / tb.total_valid_baskets, 6) AS support,

    -- Confidence A -> B: P(B | A) = pair_orders / baskets containing A
    ROUND(pc.pair_orders::NUMERIC / NULLIF(bca.baskets_containing_product, 0), 4) AS confidence_a_to_b,

    -- Confidence B -> A: P(A | B) = pair_orders / baskets containing B
    ROUND(pc.pair_orders::NUMERIC / NULLIF(bcb.baskets_containing_product, 0), 4) AS confidence_b_to_a,

    -- Lift: Confidence(A->B) / baseline probability of B
    -- baseline P(B) = baskets_containing_B / total_valid_baskets
    ROUND(
        (pc.pair_orders::NUMERIC / NULLIF(bca.baskets_containing_product, 0))
        / NULLIF(bcb.baskets_containing_product::NUMERIC / tb.total_valid_baskets, 0)
    , 4) AS lift

FROM pair_counts_filtered pc
JOIN dim_product pa ON pc.product_a = pa.stock_code
JOIN dim_product pb ON pc.product_b = pb.stock_code
JOIN product_basket_counts bca ON pc.product_a = bca.stock_code
JOIN product_basket_counts bcb ON pc.product_b = bcb.stock_code
CROSS JOIN total_baskets tb;

-- F. Reading the results

-- Strongest pairs by lift, among already-volume-filtered pairs:
SELECT * FROM market_basket_results
ORDER BY lift DESC
LIMIT 25;

--Highest-confidence "if A, then recommend B" candidates:
SELECT product_a, product_a_description, product_b, product_b_description,
       pair_orders, confidence_a_to_b, lift
FROM market_basket_results
ORDER BY confidence_a_to_b DESC
LIMIT 25;

-- Highest pair volume
SELECT * FROM market_basket_results
ORDER BY pair_orders DESC
LIMIT 25;

