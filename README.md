# E-Commerce Executive Dashboard

An end-to-end e-commerce analytics project built using the **Online Retail II** transactional dataset.

The project focuses on transforming raw retail transaction data into a reliable analytical dataset and using it to develop an executive-level dashboard for monitoring sales performance and deriving business insights.

## Project Overview

The dataset contains retail transactions including invoices, products, quantities, prices, customers, dates, and countries.

The project follows a structured analytics pipeline:

```text
Raw Dataset
     |
     v
Data Profiling
     |
     v
Data Cleaning
     |
     v
Data Validation
     |
     v
PostgreSQL
     |
     v
SQL Analysis
     |
     v
Power BI
     |
     v
E-Commerce Executive Dashboard
```

## Dataset

**Dataset:** Online Retail II

The raw dataset contains:

* **1,067,371 rows**
* **8 columns**
* Transaction data spanning **December 2009 to December 2011**

Main fields:

* Invoice
* StockCode
* Description
* Quantity
* InvoiceDate
* Price
* Customer ID
* Country

## Current Progress

### Completed

* Data profiling
* Data quality investigation
* Duplicate analysis
* Transaction-type analysis
* StockCode investigation
* Missing-value analysis
* Data cleaning
* Revenue calculation
* Transaction classification
* Python validation
* PostgreSQL database setup
* Data loading
* SQL transformations and analysis
* Analytical queries
* Documentation

### Upcoming

* Power BI dashboard
* Final business insights

## Data Cleaning Summary

The raw dataset contained **34,335 exact duplicate rows**, which were removed.

Additional explicitly invalid or non-analytical records were removed:

* `TEST001`
* `TEST002`
* `GIFT`
* `DCGSLGIRL`
* `DCGSLBOY`

A total of **20 rows** were removed for these exclusions.

The cleaned dataset contains: **1,033,016 rows**

The cleaning process also:

* normalized column names and data types
* normalized StockCode casing
* normalized the single cancellation record with positive quantity
* classified transactions as `Cancelled`, `Return/Adjusted`, or `Completed`
* retained legitimate fees, charges, discounts, adjustments, and other monetary transactions
* retained missing Customer IDs and descriptions
* created date-derived fields
* calculated Gross Revenue, Return Value, and Net Revenue

## Validation

The cleaned dataset was validated against the raw dataset for:

* row counts
* duplicate removal
* invoice counts
* customer counts
* product counts
* date range
* missing values
* cancellation/quantity consistency
* revenue calculations

The final cleaned dataset contains **zero exact duplicate rows**.

Revenue calculations also reconcile according to:

```text
Net Revenue = Gross Revenue - Return Value
```

## Repository Structure

```text
e-commerce-executive-dashboard/
│
├── data/
│   ├── raw/
|   ├── processed/
│   └── cleaned/
│
├── python/
|   ├── 00_data_conversion.ipynb
│   ├── 01_data_profiling.ipynb
│   ├── 02_data_cleaning.ipynb
│   └── 03_data_validation.ipynb
│
├── sql/
|   ├── 01_database_setup.sql
│   ├── 02_raw_load.sql
│   ├── 03_clean_transactions.sql
│   ├── 04_dimensions.sql
│   ├── 05_fact_sales.sql
│   ├── 06_revenue_analysis.sql
│   ├── 07_customer_analysis.sql
│   ├── 08_rfm_analysis.sql
│   ├── 09_retension_analysis.sql
│   ├── 10_product_analysis.sql
│   ├── 11_market_basket.sql
│   └── 12_geographic_analysis.sql
│
├── powerbi/
│
├── documentation/
│   ├── power bi/
|   ├── sql/
|   |      └── postgresql_layer.md
|   ├── python/
|   |      └── python_layer.md
│   └── business_insights.md
|
|
├── .gitignore
└── README.md
```

## Tools

* Python
* Pandas
* PostgreSQL
* SQL
* Power BI
* Git
* GitHub

## Project Status

**Current stage: PostgreSQL, SQL analysis completed.**

The downstream Power BI dashboard stages are yet to be completed.
