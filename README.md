# Texas State Employee Salary Analysis — Python → MySQL → Power BI Pipeline

End-to-end analytics project: 149K Texas state employee salary records cleaned with
Python, analyzed in MySQL, and delivered as an interactive two-page Power BI dashboard.

![Overview Page](images/dashboard_page1.png)

## Pipeline

```
salary.csv (raw export, 149K rows, 21 columns)
        │
        ▼
prepare_data.py ──── pandas: keep 15 analysis columns, strip padded whitespace
        │
        ▼
salary_clean.csv
        │
        ▼
MySQL 8 (texas_salary.employees)
        │
        ├── analysis_queries.sql ── 17 analytical queries
        │                           (window functions, CTEs, quality checks)
        ▼
powerbi_views.sql ── 6 pre-aggregated views for the dashboard
        │
        ▼  (ODBC DSN)
Power BI ── 2-page dashboard + 4 DAX measures + interactive slicers
```

## Data preparation (Python)

`prepare_data.py` trims the padded whitespace the source adds to every text
field, drops empty metadata and flag columns, and writes a tidy 15-column CSV
ready for the MySQL load. `exploratory_analysis.ipynb` covers the initial EDA
that shaped which questions the SQL analysis pursued.

## Analysis (SQL)

`analysis_queries.sql` contains 17 queries covering salary distribution, agency
comparisons, gender pay gaps, tenure effects, ethnicity representation, and
workload patterns. Techniques used include window functions (RANK, NTILE,
AVG OVER), CTEs, self-joins, and sample-size filters (HAVING thresholds) so
small groups don't distort comparisons. One correlated subquery was rewritten
as a window function after timing out on 149K rows — runtime dropped to about
a second.

### Sample result — gender pay gap by agency (50+ employees of each gender)

| agency_name | male_avg | female_avg | gap_pct |
|---|---|---|---|
| EMPLOYEES RETIREMENT SYSTEM | 107,871 | 78,397 | 27.3 |
| TEACHER RETIREMENT SYSTEM | 114,244 | 83,692 | 26.7 |
| DEPARTMENT OF PUBLIC SAFETY | 67,115 | 50,195 | 25.2 |

## Dashboard

**Page 1 — Overview:** KPI cards (149K employees, $50.7K average salary,
$553.5K maximum salary, $7.58bn total payroll), top 10 agencies by average
salary, workforce by salary band, and average salary by tenure.

**Page 2 — Pay Equity:** gender pay gap by agency in a data-bar table,
average salary by ethnicity, and slicer-driven DAX measure cards (median,
average, headcount) that recalculate live for any agency or gender selection.

![Pay Equity Page](images/dashboard_page2.png)

## Key findings

- Retirement system agencies show the widest gender pay gaps (26–27%)
- Women out-earn men in only around 10 of 100+ agencies, including both state
  schools for disability education
- Median salary ($44.6K) trails the mean ($50.7K) — a right-skewed
  distribution pulled upward by top earners
- Asian employees are the highest average earners; a sum-based view inverts
  this ranking due to headcount differences — a classic aggregation pitfall
  handled explicitly in the dashboard
- Pay rises consistently with tenure: employees with 20+ years of service
  average roughly 60% more than new hires

## Architecture notes

- SQL views are pre-aggregated summaries feeding fixed visuals; the raw table
  powers slicers and DAX measures — one view per visual, raw table for
  interactivity
- Auto-created relationships between views were removed deliberately: the
  views are standalone aggregates, so cross-filtering them is meaningless
- The connection uses a MySQL ODBC DSN after resolving the
  caching_sha2_password authentication incompatibility between MySQL 8 and
  Power BI's .NET connector

## Repository contents

| Path | Description |
|---|---|
| `python/prepare_data.py` | pandas cleaning script (raw → clean CSV) |
| `python/exploratory_analysis.ipynb` | EDA notebook |
| `sql/analysis_queries.sql` | 17 analytical queries |
| `sql/powerbi_views.sql` | 6 dashboard views |
| `dashboard/Texas_State_Employee_Salary_Analysis.pbix` | Power BI dashboard file |
| `dashboard/dax_measures.md` | DAX measures with explanations |
| `images/` | Dashboard screenshots |

> The dataset (~149K rows) is not included in this repository because it
> contains employee names. It is a publicly available Texas state employee
> salary export.

## Tools

Python (pandas) · MySQL 8 · MySQL Workbench · Power BI Desktop · DAX · ODBC
