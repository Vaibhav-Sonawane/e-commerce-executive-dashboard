-- 04_dimensions.sql

-- dim_customer

DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer AS
WITH country_counts AS (
    SELECT
        customer_id,
        country,
        COUNT(*) AS transaction_count
    FROM clean_transactions
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, country
),
ranked_countries AS (
    SELECT
        customer_id,
        country,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY transaction_count DESC, country ASC
        ) AS rn
    FROM country_counts
)
SELECT
    customer_id,
    country AS primary_country
FROM ranked_countries
WHERE rn = 1;

-- dim_product

DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product AS
SELECT DISTINCT ON (stock_code)
    stock_code,
    description
FROM (
    SELECT
        stock_code,
        description,
        COUNT(*) AS description_frequency
    FROM clean_transactions
    WHERE stock_code IS NOT NULL
    GROUP BY stock_code, description
) freq
ORDER BY stock_code, description_frequency DESC;

ALTER TABLE dim_product ADD PRIMARY KEY (stock_code);

ALTER TABLE dim_product ADD COLUMN is_admin_code BOOLEAN DEFAULT FALSE;

UPDATE dim_product
SET is_admin_code = TRUE
WHERE stock_code IN (
    'POST',
    'D',
    'DOT',
    'M',
    'BANK CHARGES',
    'PADS',
    'ADJUST',
    'ADJUST2',
    'S',
    'B',
    'AMAZONFEE',
    'CRUK'
);

-- dim_country

DROP TABLE IF EXISTS dim_country;

CREATE TABLE dim_country AS
SELECT DISTINCT country
FROM clean_transactions
WHERE country IS NOT NULL;

ALTER TABLE dim_country ADD PRIMARY KEY (country);

-- dim_date

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
SELECT
    d::DATE AS date,
    EXTRACT(YEAR FROM d)::INTEGER AS year,
    EXTRACT(MONTH FROM d)::INTEGER AS month,
    TO_CHAR(d, 'Month') AS month_name,
    EXTRACT(QUARTER FROM d)::INTEGER AS quarter,
    EXTRACT(ISODOW FROM d)::INTEGER AS day_of_week,
    TO_CHAR(d, 'Day') AS day_name,
    TO_CHAR(d, 'YYYY-MM') AS year_month
FROM generate_series('2009-12-01'::date, '2011-12-31'::date, '1 day'::interval) AS d;

ALTER TABLE dim_date ADD PRIMARY KEY (date);

-- Integrity check

SELECT customer_id, COUNT(*) FROM dim_customer GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT country, COUNT(*) FROM dim_country GROUP BY country HAVING COUNT(*) > 1;
SELECT stock_code, COUNT(*) FROM dim_product GROUP BY stock_code HAVING COUNT(*) > 1;
SELECT date, COUNT(*) FROM dim_date GROUP BY date HAVING COUNT(*) > 1;