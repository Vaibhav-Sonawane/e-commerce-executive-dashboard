# SQL Stage — Business Insights

---

## Revenue Findings

| Measure                                                          |                               Value |
| ---------------------------------------------------------------- | ----------------------------------: |
| Net Revenue trend, period start → end                            | 796535.0000 → 432719.0600 (-45.68%) |
| MoM growth (most recent month)                                   |                             -70.28% |
| YoY growth (most recent comparable month)                        |                             -42.05% |
| Primary driver of change (Customers / Orders per Customer / AOV) |                                 N/A |

**Observation:** Net revenue declined 45.68% from the beginning of the documented period (December 2009) to the end (December 2011). The most recent month recorded a sharp 70.28% MoM decline and 42.05% YoY decline.

**Diagnosis:** The methodology provides overall AOV, orders per customer, and customer metrics, but does not provide the corresponding period-start and period-end decomposition required to identify which of Customers, Orders per Customer, or AOV was the primary driver.

**Implication:** The latest revenue position indicates significant deterioration relative to both the preceding month and the comparable prior-year month.

**Action:** Treat the December decline as a material revenue-performance signal and investigate the underlying customer, order-frequency, and AOV movements before attributing the decline to a specific driver.

---

## Customer / RFM Findings

| Measure                             |        Value |
| ----------------------------------- | -----------: |
| Revenue share, top 10% of customers |       63.88% |
| At-Risk customers                   |          837 |
| At-Risk historical revenue          | 1331570.6320 |
| At-Risk % of total revenue          |        8.17% |

**Observation:** The top 10% of customers account for 63.88% of total revenue, while the documented At-Risk measure represents 837 customers and 8.17% of total revenue.

**Diagnosis:** Revenue is highly concentrated among a relatively small group of customers, creating material exposure to changes in high-value customer engagement.

**Implication:** A disproportionate share of historical revenue is tied to customers showing declining engagement.

**Action:** Prioritize retention outreach toward high-value At-Risk customers specifically, not the At-Risk segment as a whole.

---

## Product Findings

| Measure                                   | Value                              |
| ----------------------------------------- | ---------------------------------- |
| Top product by revenue                    | REGENCY CAKESTAND 3 TIER           |
| Top product by units                      | WORLD WAR 2 GLIDERS ASSTD DESIGNS  |
| Top product by customer reach             | WHITE HANGING HEART T-LIGHT HOLDER |
| Overlap between revenue and unit rankings | 2 of top 3                         |

**Observation:** REGENCY CAKESTAND 3 TIER leads revenue, while WORLD WAR 2 GLIDERS ASSTD DESIGNS leads units. WHITE HANGING HEART T-LIGHT HOLDER leads customer reach. Two products — WHITE HANGING HEART T-LIGHT HOLDER and JUMBO BAG RED RETROSPOT — appear in both the top-three revenue and top-three unit rankings.

**Diagnosis:** Product performance differs depending on whether the objective is revenue generation, unit volume, or customer reach.

**Implication:** No single product dominates all three dimensions, so product decisions should distinguish between value, volume, and reach.

**Action:** Prioritize products according to the relevant commercial objective rather than using a single ranking as the measure of product performance.

---

## Market Basket Analysis Findings

| Product A | Product B | Pair Orders |    Lift |
| --------- | --------- | ----------: | ------: |
| 23632     | 85099B    |          10 | 10.3726 |
| 85049a    | 85099C    |          49 | 21.3080 |
| 23611     | 84032A    |          15 | 58.6688 |

**Observation:** The documented product pairs show strong association, with lift values ranging from 10.3726 to 58.6688 and pair-order counts from 10 to 49 among the selected results.

**Diagnosis:** These pairs show sufficient transaction volume and strong statistical association.

**Implication:** These are concrete candidates for checkout cross-sell prompts or bundling.

**Action:** Pilot these product pairs as targeted checkout cross-sell or bundle candidates and measure conversion performance rather than assuming an AOV increase.

---

## Geographic Findings

| Measure                             | Value                          |
| ----------------------------------- | ------------------------------ |
| Top country by revenue              | United Kingdom — 15985109.6970 |
| Top country by revenue per customer | EIRE — 121990.76               |
| Same country in both?               | N                              |

**Observation:** The United Kingdom is by far the leading market by revenue, while EIRE has the highest documented revenue per customer.

**Diagnosis:** The geographic metrics reflect different market characteristics: the UK has substantial scale with 5,408 customers and 49,088 orders, whereas EIRE's revenue-per-customer figure is based on only 5 customers.

**Implication:** The UK represents the strongest revenue-scale market, while the EIRE revenue-per-customer result should be interpreted cautiously because of its very small customer base.

**Action:** Prioritize the UK for scale-based commercial analysis while treating EIRE's exceptionally high revenue per customer as a small-sample signal rather than a broadly representative market benchmark.

---

## Reconciliation Statement**

| Check                                     |     Status     |
| ----------------------------------------- | :------------: |
| Net Revenue: PostgreSQL vs. Python        |      PASS      |
| Distinct orders: PostgreSQL vs. Python    |      PASS      |
| Distinct customers: PostgreSQL vs. Python |      PASS      |
| Distinct products: PostgreSQL vs. Python  |      PASS      |

The methodology documents Python-side distinct customers of **5,941** versus **5,940** in the fact table. Therefore, the customer reconciliation cannot correctly be marked as PASS based on the documented results.

All other documented reconciliation checks pass: Net Revenue is **18,854,583.058** on both sides, distinct orders are **53,608** on both sides, and distinct products are **5,300** on both sides.