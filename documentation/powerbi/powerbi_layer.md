# Power BI Semantic Model & Dashboard

This document records the Power BI model architecture, DAX measure design, and dashboard reconciliation applied on top of the PostgreSQL analytical layer.

### Step 1: Connect and Import

Power BI Desktop directly retrieves the data from PostgreSQL, using inbuilt import data function.

Tables imported:

| Table                   | Role                                         |
| ----------------------- | -------------------------------------------- |
| `fact_sales`            | Fact table                                   |
| `dim_customer`          | Dimension                                    |
| `dim_product`           | Dimension                                    |
| `dim_date`              | Dimension                                    |
| `dim_country`           | Dimension                                    |
| `customer_summary`      | Customer-level precomputed metrics           |
| `rfm_segments`          | Customer-level RFM scores and segment labels |
| `market_basket_results` | Precomputed product-pair metrics             |

`staging_transactions`, `clean_transactions`, and other intermediate SQL working tables were **not** imported.

---

### Step 2: Model Relationships

```text
                        fact_sales
                            |                            
      +--------------+-------------+------------+
      |              |             |            |
dim_product    dim_customer    dim_date    dim_country
                     |
            +-----------------+
            |                 |
    customer_summary     rfm_segment

```

`dim_date` was marked as the model's Date Table (on the `date` column), required for time-intelligence DAX functions.

| Relationship                         | Cardinality | Cross-filter direction | Status |
| ------------------------------------ | ----------- | ---------------------- | ------ |
| `fact_sales` -> `dim_customer`       | Many-to-one | Single                 | active |
| `fact_sales` -> `dim_product`        | Many-to-one | Single                 | active |
| `fact_sales` -> `dim_date`           | Many-to-one | Single                 | active |
| `fact_sales` -> `dim_country`        | Many-to-one | Single                 | active |
| `dim_customer` -> `customer_summary` | One-to-one  | Both                   | active |
| `dim_customer` -> `rfm_segments`     | One-to-one  | Both                   | active |

---

### Step 3: DAX Architecture Decision

RFM scoring and segment labeling are owned by PostgreSQL (`08_rfm_analysis.sql`), not recalculated in DAX. Power BI's RFM measures (`Recency`, `Frequency`, `Monetary`, `RFM Score`, `RFM Segment`) are pass-throughs exposing the precomputed `rfm_segments` columns as measures. This keeps the two layers from implementing the same scoring logic twice under different rules.

Full measure list and formulas: see `dax_measures.md`.

---

### Step 4: Dashboard Pages

| Page                   | Business Question | Key Visuals |
| ---------------------- | --- | --- |
| Executive Overview     | How is the business performing? | KPI cards (Net Revenue, Orders, Customers, AOV, Repeat Rate, YoY %); Monthly revenue trend; YoY comparison; Revenue by RFM Segment; Top Products by Revenue; Revenue by Country |
| Customer Intelligence  | Who generates value, who is at risk? | KPI cards (Customers, Historical Customer Value, Repeat Rate, At-Risk Customers, At-Risk Historical Revenue); RFM segment distribution; Frequency vs. Monetary scatter; Customer detail table |
| Product & Market Basket | What should we sell together? | Top Products by Revenue/Units; Product-pair table; Confidence vs. Lift scatter |

---

### Step 5: Slicers

| Slicer                      | Page                    |
| --------------------------- | ----------------------- |
| `dim_date[year_month]`      | Executive Overview      |
| `dim_country[country]`      | Executive Overview      |
| `rfm_segments[rfm_segment]` | Customer Intelligence   |
| `dim_product[description]`  | Product & Market Basket |

---

## Power BI Reconciliation Results

All figures compared with zero slicers/filters active, against the equivalent PostgreSQL query.

| Metric                     | PostgreSQL                                    | Power BI                                      |
| -------------------------- | --------------------------------------------: | --------------------------------------------: |
| Net Revenue                | 18854583.0580                                 | 18.85 M                                       |
| Orders                     | 53608                                         | 53.608 K                                      |
| Customers                  | 5940                                          | 5.940 K                                       |
| Units Sold                 | 10886618                                      | 10886618                                      |
| AOV                        | 351.71                                        | 351.71                                        |
| Revenue, top country       | United Kingdom, 15985109.6970                 | United Kingdom, 15985109.6970                 |
| Revenue, top product       | 22423 - (Regency Cakestand 3 tier), 314045.02 | 22423 - (Regency Cakestand 3 tier), 314045.02 |
| At-Risk customers          | 837                                           | 837                                           |
| At-Risk historical revenue | 1331570.6320                                  | 1.33 M                                        |

### Validation Conclusion

All the above rows passed the check with no discrepancies found.
