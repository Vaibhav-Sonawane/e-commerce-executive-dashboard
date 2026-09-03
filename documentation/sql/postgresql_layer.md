# PostgreSQL Data Layer

This document records the database architecture, reconciliation logic, and analytical SQL applied to the cleaned dataset after the Python cleaning stage.

### Step 1: Create Staging Table

A staging table was created to receive the Python-cleaned CSV with no business logic applied.

```text
staging_transactions (
    invoice_number, stock_code, description, quantity, invoice_date,
    unit_price, customer_id, country, transaction_date, transaction_month,
    transaction_year, transaction_time, gross_revenue, return_value,
    net_revenue, transaction_status
)
```

`customer_id` is staged as text rather than integer, because empty-string nulls from the CSV must be explicitly converted before casting.

---

### Step 2: Load Cleaned Data into Staging

The cleaned CSV was loaded into `staging_transactions` via `\copy`.

| Measure                           | Value                           |
| --------------------------------- |-------------------------------: |
| Staging row count                 | 1,033,016                       |
| Expected (from Python validation) | 1,033,016                       |

Null counts were checked immediately after load and compared against the Python-side figures:

| Column            | Expected Nulls (Python) | Staging Nulls (SQL) |
| ----------------- | ----------------------: | ------------------: |
| `customer_id`     | 235,147                 | 235,147             |
| `description`     | 4,271                   | 4271                |
| All other columns | 0                       | 0                   |

---

### Step 3: Build Clean Transactions Layer

`clean_transactions` was built on top of staging with the following operations:

* `customer_id` cast from text to nullable integer via `NULLIF(customer_id, '')::INTEGER`
* `is_cancelled` derived as `transaction_status = 'Cancelled'`
* Gross/Return/Net Revenue **independently re-derived in SQL**, using only `quantity` and `unit_price` (not the Python-computed columns), as a reconciliation check

```text
sql_gross_revenue = CASE WHEN quantity >= 0 THEN quantity * unit_price ELSE 0 END
sql_return_value  = CASE WHEN quantity < 0  THEN ABS(quantity * unit_price) ELSE 0 END
sql_net_revenue   = quantity * unit_price
```

No deduplication was repeated at this layer. Python already removed all exact duplicate rows (`drop_duplicates()`) prior to export. This step instead **verifies** zero duplicates remain:

```sql
GROUP BY invoice_number, stock_code, quantity, invoice_date, unit_price, customer_id
HAVING COUNT(*) > 1
```

| Measure                | Value  |
| ---------------------- | -----: |
| Duplicate groups found | 0      |

---

### Step 4: Revenue Reconciliation

Python-derived and SQL-derived revenue totals were compared directly from `clean_transactions`.

| Measure       | Python-side    | SQL-side     | Result |
| ------------- | -------------: | -----------: | :----: |
| Gross Revenue | 20,317,358.308 | 20317358.308 | PASS   |
| Return Value  | 1,462,775.250  | 1462775.250  | PASS   |
| Net Revenue   | 18,854,583.058 | 18854583.058 | PASS   |

---

### Step 5: Build Dimensional Model

Four dimension tables were built from `clean_transactions`, and one fact table.

```text
                    fact_sales
                        |
     +-------------+----------+-----------+
     |             |          |           |
dim_customer  dim_product  dim_date  dim_country
```

**Fact grain:** one row = one transaction line, for one invoice, for one product.

`dim_customer` — one row per distinct `customer_id`, with `primary_country` resolved as the most frequent country per customer.

`dim_product` — one row per distinct `stock_code`, with `description` resolved as the most frequent description per code. An `is_admin_code` flag was added to distinguish genuine products from financial/operational codes:

| stock_code               | is_admin_code            |
| ------------------------ | :----------------------: |
| `POST`                   | TRUE                     |
| `D`                      | TRUE                     |
| `DOT`                    | TRUE                     |
| `M`                      | TRUE                     |
| `BANK CHARGES`           | TRUE                     |
| `PADS`                   | TRUE                     |
| `ADJUST` / `ADJUST2`     | TRUE                     |
| `S`                      | TRUE                     |
| `B`                      | TRUE                     |
| `AMAZONFEE`              | TRUE                     |
| `CRUK`                   | TRUE                     |
| `DCGSSBOY` / `DCGSSGIRL` | FALSE (genuine products) |
| gift card codes          | FALSE (genuine products) |

This flag does not exclude these codes from the database or from revenue totals — they were retained in Python cleaning because they represent monetary activity (see Step 7 of Data Cleaning Steps). It only excludes them from product-performance rankings and Market Basket Analysis, where a financial adjustment code is not a meaningful "product" result.

`dim_date` — generated as a full continuous calendar (`generate_series`) covering the dataset's date range, not limited to dates that appear in transactions. This is required for gap-free month-over-month and year-over-year calculations.

`dim_country` — one row per distinct country.

---

### Step 6: Build Fact Table

`fact_sales` was built at the documented grain, with foreign keys to `dim_product`, `dim_date`, and `dim_country`, and indexes on all four join columns.

Grain check (must return zero rows):

```sql
GROUP BY invoice_number, stock_code HAVING COUNT(*) > 1
```

| Measure                     | Value         | Expected       |
| --------------------------- | ------------: | -------------: |
| Total fact rows             | 1033016       | 1,033,016      |
| Distinct orders             | 53608         | 53,608         |
| Distinct customers          | 5940          | 5,941          |
| Distinct products           | 5300          | 5,300          |
| Total Net Revenue           | 18854583.058  | 18,854,583.058 |
| Min transaction date        | 2009-12-01    | 2009-12-01     |
| Max transaction date        | 2011-12-09    | 2011-12-09     |
| Grain check duplicate rows  | 0             | 0              |

---

# SQL Analytical Findings

The following sections record the output of each analytical script. All figures below are placeholders pending execution against the live database.

### Revenue Analysis

| Measure              | Value         |
| -------------------- | ------------: |
| Gross Revenue        | 20317358.3080 |
| Returns              | 1462775.2500  |
| Net Revenue          | 18854583.0580 |
| Orders               | 53608         |
| Customers            | 5940          |
| Units Sold           | 10886618      |
| AOV                  | 351.71        |
| Revenue per Customer | 3174.17       |
| Orders per Customer  | 9.02          |

Monthly trend, MoM growth, and YoY growth:

| year_month |  net_revenue | prev_month_revenue | mom_growth_pct | prev_year_revenue | yoy_growth_pct |
| ---------- | -----------: | -----------------: | -------------: | ----------------: | -------------: |
| 2009-12    |  796535.0000 |                    |                |                   |                |
| 2010-01    |  622389.5020 |        796535.0000 |         -21.86 |                   |                |
| 2010-02    |  530518.2260 |        622389.5020 |         -14.76 |                   |                |
| 2010-03    |  763247.2410 |        530518.2260 |          43.87 |                   |                |
| 2010-04    |  587904.1920 |        763247.2410 |         -22.97 |                   |                |
| 2010-05    |  613270.7200 |        587904.1920 |           4.31 |                   |                |
| 2010-06    |  677073.8700 |        613270.7200 |          10.40 |                   |                |
| 2010-07    |  573333.6900 |        677073.8700 |         -15.32 |                   |                |
| 2010-08    |  654774.3900 |        573333.6900 |          14.20 |                   |                |
| 2010-09    |  851105.9610 |        654774.3900 |          29.98 |                   |                |
| 2010-10    | 1041708.1100 |        851105.9610 |          22.39 |                   |                |
| 2010-11    | 1416697.2020 |       1041708.1100 |          36.00 |                   |                |
| 2010-12    |  746723.6100 |       1416697.2020 |         -47.29 |       796535.0000 |          -6.25 |
| 2011-01    |  558448.5600 |        746723.6100 |         -25.21 |       622389.5020 |         -10.27 |
| 2011-02    |  497026.4100 |        558448.5600 |         -11.00 |       530518.2260 |          -6.31 |
| 2011-03    |  682013.9800 |        497026.4100 |          37.22 |       763247.2410 |         -10.64 |
| 2011-04    |  492367.8410 |        682013.9800 |         -27.81 |       587904.1920 |         -16.25 |
| 2011-05    |  722094.1000 |        492367.8410 |          46.66 |       613270.7200 |          17.74 |
| 2011-06    |  689977.2300 |        722094.1000 |          -4.45 |              1.91 |           1.91 |
| 2011-07    |  680156.9910 |        689977.2300 |          -1.42 |       573333.6900 |          18.63 |
| 2011-08    |  681386.4600 |        680156.9910 |           0.18 |       654774.3900 |           4.06 |
| 2011-09    | 1017596.6820 |        681386.4600 |          49.34 |       851105.9610 |          19.56 |
| 2011-10    | 1069368.2300 |       1017596.6820 |           5.09 |      1041708.1100 |           2.66 |
| 2011-11    | 1456145.8000 |       1069368.2300 |          36.17 |      1416697.2020 |           2.78 |
| 2011-12    |  432719.0600 |       1456145.8000 |         -70.28 |       746723.6100 |         -42.05 |

---

### Customer Analysis

| Segment              | % of Total Revenue |
| -------------------- | -----------------: |
| Top 1% of customers  | 31.42 %            |
| Top 5% of customers  | 51.69 %            |
| Top 10% of customers | 63.88 %            |
| Top 20% of customers | 77.60 %            |

| Measure                      | Value     |
| ---------------------------- | --------: |
| Average revenue per customer | 2742.39   |
| Median revenue per customer  | 823.05    |
| Max revenue, single customer | 570380.61 |

---

### RFM Segmentation

Reference Date: `MAX(transaction_date) + 1 day` = "2011-12-10"

| Segment             | Customers | Segment Revenue |
| ------------------- | --------: | --------------: |
| Champions           | 1315      | 11464973.405    |
| Loyal Customers     | 1412      | 2584409.3470    |
| At Risk             | 837       | 1331570.6320    |
| Potential Loyalists | 1539      | 511872.3120     |
| Need Attention      | 452       | 210772.3000     |
| New Customers       | 361       | 135429.8910     |
| Lost                | 24        | 50759.9010      |

| Measure                    | Value        |
| -------------------------- | -----------: |
| At-Risk customers          | 837          |
| At-Risk historical revenue | 1331570.6320 |
| At-Risk % of total revenue | 8.17 %       |

---

### Retention Analysis

New vs. repeat customers by month:

| activity_month | new_customers | repeat_customers |
| -------------- | ------------: | ---------------: |
| 2009-12-01     |          1044 |                0 |
| 2010-01-01     |           395 |              391 |
| 2010-02-01     |           361 |              444 |
| 2010-03-01     |           436 |              675 |
| 2010-04-01     |           291 |              707 |
| 2010-05-01     |           254 |              808 |
| 2010-06-01     |           269 |              826 |
| 2010-07-01     |           183 |              805 |
| 2010-08-01     |           158 |              806 |
| 2010-09-01     |           242 |              960 |
| 2010-10-01     |           378 |             1197 |
| 2010-11-01     |           322 |             1361 |
| 2010-12-01     |            77 |              871 |
| 2011-01-01     |            71 |              712 |
| 2011-02-01     |           123 |              675 |
| 2011-03-01     |           178 |              842 |
| 2011-04-01     |           105 |              794 |
| 2011-05-01     |           109 |              970 |
| 2011-06-01     |           108 |              943 |
| 2011-07-01     |           102 |              891 |
| 2011-08-01     |           106 |              874 |
| 2011-09-01     |           187 |             1115 |
| 2011-10-01     |           221 |             1204 |
| 2011-11-01     |           192 |             1519 |
| 2011-12-01     |            28 |              658 |

---

### Product Analysis

| Rank | Top Products by Revenue | Top Products by Units | Top Products by Customer Reach |
| --- | --- | --- | --- |
| 1 | "REGENCY CAKESTAND 3 TIER" | WORLD WAR 2 GLIDERS ASSTD DESIGNS | WHITE HANGING HEART T-LIGHT HOLDER |
| 2 | WHITE HANGING HEART T-LIGHT HOLDER | WHITE HANGING HEART T-LIGHT HOLDER | REGENCY CAKESTAND 3 TIER |
| 3 | JUMBO BAG RED RETROSPOT | JUMBO BAG RED RETROSPOT | BAKING SET 9 PIECE RETROSPOT |

---

### Market Basket Analysis

Minimum pair-count threshold applied: 10

| Product A | Product B | Pair Orders | Support | Confidence (A->B) |      Lift |
| --------- | --------- | ----------: | ------: | ----------------: | --------: |
| 23632     | 85099B    |          10 |     N/A |            1.0000 |   10.3726 |
| 85049a    | 85099C    |          49 |     N/A |            0.9608 |   21.3080 |
| 23611     | 84032A    |          15 |     N/A |            0.9375 |   58.6688 |
| 84745A    | 84745B    |          14 |     N/A |            0.9333 | 2274.4784 |
| 22916     | 22917     |         232 |     N/A |            0.9317 |  153.1729 |

Valid basket definition: `transaction_status = 'Completed'` AND `is_admin_code = FALSE`.

Pair-counting join condition: `a.stock_code < b.stock_code`, to prevent each unordered pair from being counted twice.

---

### Geographic Analysis

| Country        |       Revenue | Customers | Orders |     AOV | Revenue per Customer |
| -------------- | ------------: | --------: | -----: | ------: | -------------------: |
| United Kingdom | 15985109.6970 |      5408 |  49088 |  325.64 |              2955.83 |
| EIRE           |   609953.7800 |         5 |    806 |  756.77 |            121990.76 |
| Netherlands    |   548330.7000 |        23 |    250 | 2193.32 |             23840.47 |
| Germany        |   411959.1610 |       107 |   1095 |  376.22 |              3850.09 |
| France         |   321733.3900 |        95 |    746 |  431.28 |              3386.67 |

Minimum customer threshold applied for "most valuable market" comparisons: 10. The dataset is heavily UK-concentrated; smaller-country comparisons should be read with this in mind.
