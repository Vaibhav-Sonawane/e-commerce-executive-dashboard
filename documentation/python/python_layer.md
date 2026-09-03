# Data Quality Findings

This document records the data profiling, data-quality findings, cleaning decisions, and validation performed on the Online Retail II dataset before downstream analysis.

## Data Profiling Results

### 1. Dataset Overview

The dataset contains **1,067,371 rows** and **8 columns**.

#### Columns

* `Invoice`
* `StockCode`
* `Description`
* `Quantity`
* `InvoiceDate`
* `Price`
* `Customer ID`
* `Country`

#### Data Types

| Column        | Data Type      |
| ------------- | -------------- |
| `Invoice`     | object         |
| `StockCode`   | object         |
| `Description` | object         |
| `Quantity`    | int64          |
| `InvoiceDate` | datetime64[ns] |
| `Price`       | float64        |
| `Customer ID` | float64        |
| `Country`     | object         |

---

### 2. Missing Values

| Column        | Missing Values |
| ------------- | -------------: |
| `Invoice`     |              0 |
| `StockCode`   |              0 |
| `Description` |          4,382 |
| `Quantity`    |              0 |
| `InvoiceDate` |              0 |
| `Price`       |              0 |
| `Customer ID` |        243,007 |
| `Country`     |              0 |

The primary missing-value issues are therefore in:

* `Customer ID` — 243,007 missing values
* `Description` — 4,382 missing values

`Customer ID` missingness is particularly relevant for customer-level analysis.

Missing `Customer ID` values are retained during cleaning because the absence of customer identification does not make the transaction itself invalid for transaction-level revenue analysis.

---

### 3. Duplicate Records

The dataset contains **34,335 exact duplicate rows**.

Exact duplicates were identified by comparing all available columns. Further investigation showed that some identical transaction lines were repeated multiple times within the same invoice, including cases where the same line occurred up to 20 times.

Because these records are identical across all available fields, they were treated as duplicate source records rather than separate transaction lines.

Only exact duplicates were removed. No deduplication was performed using combinations such as `Invoice + StockCode`, because legitimate transaction lines can otherwise be incorrectly collapsed.

---

### 4. Cardinality / Unique Values

| Column        | Unique Values |
| ------------- | ------------: |
| `Invoice`     |        53,628 |
| `StockCode`   |         5,305 |
| `Description` |         5,698 |
| `Quantity`    |         1,057 |
| `InvoiceDate` |        47,635 |
| `Price`       |         2,807 |
| `Customer ID` |         5,942 |
| `Country`     |            43 |

The difference between the number of `StockCode` and `Description` values indicates that the relationship between these fields is not strictly one-to-one.

---

### 5. Date Range

The transaction data covers:

* **Minimum:** `2009-12-01 07:45:00`
* **Maximum:** `2011-12-09 12:50:00`

`InvoiceDate` contains no missing values and is stored as `datetime64[ns]`.

---

### 6. Quantity Profiling

Quantity contains both positive and negative values.

| Condition                                        | Row Count |
| ------------------------------------------------ | --------: |
| Quantity < 0 and Invoice does not start with `C` |     3,457 |
| Quantity > 0 and Invoice does not start with `C` | 1,044,420 |
| Quantity < 0 and Invoice starts with `C`         |    19,493 |
| Quantity > 0 and Invoice starts with `C`         |         1 |

The observed quantity range is:

* **Minimum:** `-80,995`
* **Maximum:** `80,995`

#### Findings

Most positive-quantity transactions are associated with invoices that do not start with `C`.

Invoices beginning with `C` are predominantly associated with negative quantities, indicating cancellation-related transactions.

One `C` invoice was found with a positive quantity. This record was treated as a cancellation because the invoice prefix is the project's cancellation indicator, and its quantity sign was normalized from positive to negative during cleaning.

There are also **3,457 negative-quantity records whose invoice does not start with `C`**. These include operational records such as losses, damages, and other adjustments. Therefore, negative quantity alone cannot be treated as an indication of cancellation.

---

### 7. Price Profiling

The dataset contains **6,202 records where `Price = 0`**.

Zero-price records were found across a large number of StockCodes, with **2,971 unique StockCodes** occurring among these records.

The profiling also identified records with negative prices. These are associated with adjustment-type transactions rather than normal product sales.

For example, StockCode `B` has the description `Adjust bad debt` and contains negative prices.

Therefore, `Price <= 0` was **not** used as a general rule for removing records. Some zero- and negative-price records represent legitimate business, operational, or accounting transactions.

---

### 8. StockCode Profiling

The StockCode field contains both normal product identifiers and special transaction/operational codes.

#### Gift Cards

Gift-card StockCodes include:

* `gift_0001_10` — 10 Euro
* `gift_0001_20` — 20 Euro
* `gift_0001_30` — 30 Euro
* `gift_0001_40` — 40 Euro
* `gift_0001_50` — 50 Euro
* `gift_0001_60` — 60 Euro
* `gift_0001_70` — 70 Euro
* `gift_0001_80` — 80 Euro
* `gift_0001_90` — 90 Euro

Gift-card records show varying prices, and some records have missing descriptions or zero prices.

#### Other Special StockCodes

| StockCode      | Observed Meaning / Description                            |
| -------------- | --------------------------------------------------------- |
| `POST`         | Postage fee                                               |
| `D`            | Discount                                                  |
| `DOT`          | DOTCOM postage                                            |
| `M`            | Manual transaction                                        |
| `m`            | Manual transaction; lowercase variation of `M`            |
| `BANK CHARGES` | Bank charges                                              |
| `PADS`         | PADS TO MATCH ALL CUSHIONS                                |
| `ADJUST`       | Employee adjustments                                      |
| `ADJUST2`      | Employee adjustments                                      |
| `GIFT`         | Gift-related entry; insufficient information for analysis |
| `DCGSSBOY`     | BOYS PARTY BAG                                            |
| `DCGSSGIRL`    | GIRLS PARTY BAG                                           |
| `DCGSLGIRL`    | Gift-related entry; insufficient information for analysis |
| `DCGSLBOY`     | Gift-related entry; insufficient information for analysis |
| `S`            | Samples                                                   |
| `B`            | Adjust bad debt                                           |
| `AMAZONFEE`    | Amazon fee                                                |
| `CRUK`         | Cancer Research UK commission                             |
| `TEST001`      | Data testing entry                                        |
| `TEST002`      | Data testing entry                                        |

Special financial and operational StockCodes such as `POST`, `D`, `BANK CHARGES`, `M`, `ADJUST`, `AMAZONFEE`, and `CRUK` were retained because they represent monetary activity that can affect revenue-related calculations.

`TEST001` and `TEST002` were identified as explicit testing entries and were excluded.

`GIFT`, `DCGSLGIRL`, and `DCGSLBOY` were excluded because the observed records did not contain sufficient information to support meaningful analysis and did not contribute monetary value.

---

### 9. Description Profiling

`Description` contains **4,382 missing values**.

The profiling also identified multiple descriptions associated with the same StockCode.

Some differences represent simple wording, spelling, or formatting variations, while others are operational annotations such as:

* `missing`
* `found`
* `lost`
* `damages`
* `wrongly coded`
* `marked as ...`

An initial StockCode-to-description consistency check was performed using the most frequent description for each StockCode as the expected description.

However, this produced high inconsistency rates for several frequently occurring products. This indicates that exact matching against the most frequent description can overstate the number of genuine errors.

Therefore, description variation was treated as a **data-quality observation rather than an automatic reason for removing records**.

Missing descriptions were retained.

---

### 10. Invoice Profiling

The profiling identified **19,494 cancellation-related invoices**, based on invoices beginning with `C`.

Cancellation-related records are predominantly associated with negative quantities.

Because one `C` invoice was observed with a positive quantity, the invoice prefix was used as the cancellation indicator and the positive quantity was normalized to a negative value during cleaning.

---

### 11. Overall Data-Quality Findings

The profiling identified the following major characteristics:

1. **34,335 exact duplicate rows**
2. **243,007 missing Customer IDs**
3. **4,382 missing descriptions**
4. **19,494 cancellation-related invoices**
5. **3,457 negative-quantity records outside cancellation invoices**
6. **6,202 zero-price records**
7. **Negative-price accounting/adjustment records**
8. **Large positive and negative quantity outliers**
9. **Multiple special/non-product StockCodes**
10. **StockCode case variations**
11. **Multiple descriptions associated with the same StockCode**
12. **Operational annotations within the Description field**
13. **Gift-card and other special transaction records**

These findings indicate that the dataset contains a mixture of **normal sales transactions, cancellations, returns/adjustments, fees, manual entries, gift cards, samples, and other operational records**.

Consequently, data cleaning distinguishes between **legitimate business transactions and records that are unsuitable for analytical calculations**, rather than treating every unusual value as an error.

---

# Data Cleaning Steps

### Step 1: Normalize Column Names

The source column names were renamed to provide a consistent analytical schema.

| Original Column | Cleaned Column |
| --------------- | -------------- |
| `Invoice`       | `invoice_number`    |
| `StockCode`     | `stock_code`    |
| `Description`   | `description`  |
| `Quantity`      | `quantity`     |
| `InvoiceDate`   | `invoice_date`  |
| `Price`         | `unit_price`    |
| `Customer ID`   | `customer_id`   |
| `Country`       | `country`      |

---

### Step 2: Normalize Data Types

| Column        | Final Data Type  |
| ------------- | ---------------- |
| `invoice_number`   | `string`         |
| `stock_code`   | `string`         |
| `description` | `string`         |
| `quantity`    | `Int64`          |
| `invoice_date` | `datetime64[ns]` |
| `unit_price`   | `float64`        |
| `customer_id`  | `Int64`          |
| `country`     | `string`         |

Missing `customer_id` values were preserved using the nullable `Int64` type.

---

### Step 3: Remove Exact Duplicates

Exact duplicate rows were removed across all available columns.

```text
df.drop_duplicates(keep="first")
```

| Measure                   |      Rows |
| ------------------------- | --------: |
| Rows before deduplication | 1,067,371 |
| Rows after deduplication  | 1,033,036 |
| Rows removed              |    34,335 |

Only exact duplicates were removed. Rows were not deduplicated using partial keys such as `invoice_number + stock_code`.

---

### Step 4: Normalize Cancelled Positive Quantities

Invoices beginning with `C` were treated as cancellation-related transactions.

One cancellation record contained a positive quantity. Its quantity was normalized to a negative value.

```text
IF invoice_number starts with "C"
AND quantity > 0
THEN quantity = quantity × -1
```

Result:

* Cancellation records with positive quantity before cleaning: **1**
* Cancellation records with positive quantity after cleaning: **0**

---

### Step 5: Normalize stock_code Case

StockCodes were converted to uppercase to remove case-based inconsistencies.

```text
df["stock_code"] = df["stock_code"].str.upper()
```

This normalizes values such as:

```text
M → M
m → M
```

and:

```text
15056BL → 15056BL
15056bl → 15056BL
```

No StockCodes were removed solely because of case differences.

---

### Step 6: Classify Transaction Status

A `TransactionStatus` field was created using the following rule:

```text
IF invoice_number starts with "C"
    → Cancelled

ELSE IF quantity < 0
    → Return/Adjusted

ELSE
    → Completed
```

This keeps cancellation status distinct from negative quantity because non-cancelled negative-quantity records can represent returns, losses, damages, or adjustments.

---

### Step 7: Exclude Explicitly Invalid/Test Records

The following StockCodes were excluded:

* `TEST001`
* `TEST002`
* `GIFT`
* `DCGSLGIRL`
* `DCGSLBOY`

These records were excluded because they were either explicit testing entries or isolated/non-analytical records with insufficient information and no meaningful monetary contribution.

| Measure               |      Rows |
| --------------------- | --------: |
| Rows before exclusion | 1,033,036 |
| Rows after exclusion  | 1,033,016 |
| Rows removed          |        20 |

Breakdown:

| stock_code   | Rows Removed |
| ----------- | -----------: |
| `TEST001`   |           15 |
| `TEST002`   |            2 |
| `GIFT`      |            1 |
| `DCGSLGIRL` |            1 |
| `DCGSLBOY`  |            1 |
| **Total**   |       **20** |

Financial and operational StockCodes such as `POST`, `D`, `M`, `BANK CHARGES`, `ADJUST`, `AMAZONFEE`, and `CRUK` were retained because their transactions can contribute to monetary calculations.

---

### Step 8: Handle Missing Values

Missing `customer_id` values were retained.

Missing `description` values were also retained because the absence of a description does not by itself invalidate the transaction.

No arbitrary values such as `0`, `"Unknown"`, or `"N/A"` were substituted for missing customer_ids.

---

### Step 9: Create Date-Derived Fields

The following fields were derived from `invoice_date`:

* `TransactionDate`
* `TransactionTime`
* `TransactionYear`
* `TransactionMonth`

Examples:

```text
TransactionDate  = invoice_date.dt.date
TransactionTime  = invoice_date.dt.time
TransactionYear  = invoice_date.dt.year
TransactionMonth = invoice_date.dt.month
```

These fields support daily, monthly, and yearly analysis.

---

### Step 10: Calculate Revenue Fields

Revenue fields were calculated at the transaction-line level.

#### Normal Transactions

```text
Gross Revenue = quantity × unit_price
Return Value = 0
```

#### Return / Cancelled Transactions

```text
Gross Revenue = 0
Return Value = ABS(quantity × unit_price)
```

#### Net Revenue

```text
Net Revenue = Gross Revenue - Return Value
```

This treats return value as a positive monetary magnitude while reducing Net Revenue through the subtraction.

---

### Step 11: Save Processed Dataset

The final cleaned dataset was saved to the processed-data directory for downstream PostgreSQL loading.

```text
data/processed/
```

The processed dataset contains the cleaned transaction records together with the derived transaction-status, date, and revenue fields.

---

# Data Validation Results

The cleaned dataset was validated against the raw dataset after all cleaning operations.

## Row Counts

| Measure                      |      Rows |
| ---------------------------- | --------: |
| Raw rows                     | 1,067,371 |
| Cleaned rows                 | 1,033,016 |
| Rows removed                 |    34,355 |
| Exact duplicate rows removed |    34,335 |
| Explicitly excluded rows     |        20 |

The row-count reconciliation is:

```text
34,335 + 20 = 34,355
```

---

## Revenue Validation

### Raw Dataset

| Measure       |          Value |
| ------------- | -------------: |
| Gross Revenue | 20,814,291.998 |
| Return Value  |  1,527,041.430 |
| Net Revenue   | 19,287,250.568 |

### Cleaned Dataset

| Measure       |          Value |
| ------------- | -------------: |
| Gross Revenue | 20,317,358.308 |
| Return Value  |  1,462,775.250 |
| Net Revenue   | 18,854,583.058 |

The cleaned revenue totals reconcile according to:

```text
Gross Revenue - Return Value = Net Revenue
```

```text
20,317,358.308 - 1,462,775.250
= 18,854,583.058
```

The difference between raw and cleaned revenue is expected because duplicate and explicitly excluded records were removed.

---

## Order Validation

| Measure                   |  Count |
| ------------------------- | -----: |
| Raw distinct invoices     | 53,628 |
| Cleaned distinct invoices | 53,608 |

The reduction of 20 invoices corresponds to the 20 explicitly excluded records, which represented 20 distinct invoices.

---

## Customer Validation

| Measure                    | Count |
| -------------------------- | ----: |
| Raw distinct customers     | 5,943 |
| Cleaned distinct customers | 5,941 |

The two customers removed from the distinct-customer count occurred exclusively in records associated with `TEST001`.

---

## Product Validation

| Measure                     | Count |
| --------------------------- | ----: |
| Raw distinct StockCodes     | 5,305 |
| Cleaned distinct StockCodes | 5,300 |

The five StockCodes absent from the cleaned dataset were:

* `TEST001`
* `TEST002`
* `GIFT`
* `DCGSLGIRL`
* `DCGSLBOY`

These correspond exactly to the five explicitly excluded StockCodes.

---

## Date Range Validation

The date range remained unchanged after cleaning.

| Dataset | Minimum               | Maximum               |
| ------- | --------------------- | --------------------- |
| Raw     | `2009-12-01 07:45:00` | `2011-12-09 12:50:00` |
| Cleaned | `2009-12-01 07:45:00` | `2011-12-09 12:50:00` |

---

## Duplicate Validation

After cleaning:

```text
Exact duplicate rows remaining = 0
```

This confirms that the exact-duplicate removal rule was successfully applied.

---

## Transaction Validation

### Raw Dataset

* Cancelled invoices with positive quantity: **1**
* Non-cancelled negative-quantity records: **3,411**

### Cleaned Dataset

* Cancelled invoices with positive quantity: **0**
* Non-cancelled negative-quantity records: **3,390**

The cancellation-positive-quantity anomaly was successfully normalized without removing the transaction.

The remaining non-cancelled negative-quantity records were retained because they represent operational return, loss, damage, or adjustment activity rather than necessarily being erroneous records.

---

## Post-Cleaning Nulls

| Column        | Raw Missing | Cleaned Missing |
| ------------- | ----------: | --------------: |
| `description` |       4,382 |           4,271 |
| `customer_id` |     243,007 |         235,147 |
| Other columns |           0 |               0 |

The reduction in missing-value counts is attributable to the removal of duplicate and explicitly excluded rows. Missing values were not artificially imputed.

---

## Validation Conclusion

The cleaning and validation process resulted in **1,033,016 transaction rows**.

The validation confirms that:

1. All 34,335 exact duplicate rows were removed.
2. All 20 explicitly excluded records were removed.
3. No exact duplicates remain.
4. The cancellation positive-quantity anomaly was normalized.
5. The historical date range was preserved.
6. Missing customer_ids and descriptions were retained where applicable.
7. Revenue calculations reconcile correctly.
8. Changes in invoice, customer, and stock_code counts are explainable by the documented exclusions.
9. Financial and operational transaction types required for revenue analysis were retained.

The resulting processed dataset is therefore suitable for downstream PostgreSQL loading and analytical work.
