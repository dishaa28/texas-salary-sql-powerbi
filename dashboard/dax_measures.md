# DAX Measures Reference

All measures used in the Sales Performance Dashboard, with what each one does.

### Core measures

```DAX
Total Sales = SUM(Sales[Sales])
```
Total revenue across the current filter context (whatever slicers are applied).

```DAX
Total Profit = SUM(Sales[Profit])
```
Total profit across the current filter context.

```DAX
Total Orders = DISTINCTCOUNT(Sales[Order ID])
```
Number of *unique* orders — `DISTINCTCOUNT` so multi-line orders count once.

```DAX
Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0)
```
Profit as a share of sales. `DIVIDE` is used instead of `/` so a zero
denominator returns 0 instead of an error.

```DAX
Avg Order Value = DIVIDE([Total Sales], [Total Orders], 0)
```
Average revenue per order — a standard retail KPI.

### Time-intelligence measures

```DAX
Sales LY =
CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date Table'[Date]))
```
Total sales for the same period one year earlier. Requires a marked Date table.

```DAX
Sales YoY % =
DIVIDE([Total Sales] - [Sales LY], [Sales LY], 0)
```
Year-over-year growth rate — the headline number in most exec dashboards.

### Optional extras (nice to add)

```DAX
Running Total Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        ALLSELECTED('Date Table'[Date]),
        'Date Table'[Date] <= MAX('Date Table'[Date])
    )
)
```
Cumulative sales over time — good for an area chart.

```DAX
Sales Rank by Category =
RANKX(ALL(Sales[Category]), [Total Sales], , DESC)
```
Ranks categories by revenue — useful in a table visual.
