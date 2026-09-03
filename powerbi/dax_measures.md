# DAX Measures
---

## Revenue

```dax
Gross Revenue = SUM(fact_sales[gross_revenue])

Returns = SUM(fact_sales[return_value])

Net Revenue = SUM(fact_sales[net_revenue])

Revenue LY =
CALCULATE([Net Revenue], SAMEPERIODLASTYEAR(dim_date[date]))

YoY % =
DIVIDE([Net Revenue] - [Revenue LY], [Revenue LY], 0)

Revenue YTD =
CALCULATE([Net Revenue], DATESYTD(dim_date[date]))
```

---

## Customers

```dax
Customers =
CALCULATE(
    DISTINCTCOUNT(fact_sales[customer_id]),
    NOT ISBLANK(fact_sales[customer_id])
)

Active Customers =
CALCULATE([Customers], fact_sales[transaction_status] = "Completed")

New Customers =
CALCULATE(
    DISTINCTCOUNT(customer_summary[customer_id]),
    FILTER(
        customer_summary,
        customer_summary[first_purchase_date] >= MIN(dim_date[date]) &&
        customer_summary[first_purchase_date] <= MAX(dim_date[date])
    )
)

Repeat Customers = [Active Customers] - [New Customers]

Repeat Rate = DIVIDE([Repeat Customers], [Active Customers], 0)
```

---

## Orders

```dax
Orders = DISTINCTCOUNT(fact_sales[invoice_number])

AOV = DIVIDE([Net Revenue], [Orders], 0)

Orders per Customer = DIVIDE([Orders], [Customers], 0)

Items per Order =
DIVIDE(
    CALCULATE(SUM(fact_sales[quantity]), fact_sales[transaction_status] = "Completed"),
    [Orders],
    0
)
```

---

## Customer Value

```dax
Historical Customer Value = SUM(customer_summary[total_net_revenue])

Segment Revenue = [Net Revenue]

Segment Revenue % =
DIVIDE([Segment Revenue], CALCULATE([Net Revenue], ALL(rfm_segments)), 0)
```

---

## RFM

```dax
Recency = AVERAGE(rfm_segments[recency_days])

Frequency = AVERAGE(rfm_segments[frequency])

Monetary = AVERAGE(rfm_segments[monetary])

RFM Score =
SELECTEDVALUE(rfm_segments[r_score]) & SELECTEDVALUE(rfm_segments[f_score]) & SELECTEDVALUE(rfm_segments[m_score])

RFM Segment = SELECTEDVALUE(rfm_segments[rfm_segment])
```

---

## At-Risk Specific (For cards)

```dax
At-Risk Customers =
CALCULATE([Customers], rfm_segments[rfm_segment] = "At Risk")

At-Risk Historical Revenue =
CALCULATE([Net Revenue], rfm_segments[rfm_segment] = "At Risk")
```
