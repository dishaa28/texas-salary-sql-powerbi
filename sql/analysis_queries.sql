-- Texas state employee salary analysis
-- data: ~149k employees across 113 agencies (MySQL 8)

USE texas_salary;

-- overview: how big is the data, what's the salary range
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT agency) AS agencies,
    COUNT(DISTINCT class_title) AS job_titles,
    ROUND(AVG(annual), 0) AS avg_annual,
    ROUND(MIN(annual), 0) AS min_annual,
    ROUND(MAX(annual), 0) AS max_annual
FROM employees;


-- quick data quality check before trusting anything
SELECT
    SUM(annual <= 0) AS zero_or_neg_salary,
    SUM(hrs_per_wk <= 0) AS zero_hours,
    SUM(employ_date IS NULL) AS missing_hire_date,
    SUM(gender NOT IN ('MALE','FEMALE')) AS unknown_gender
FROM employees;


-- top paying agencies (100+ staff so one big salary doesn't skew a tiny agency)
SELECT
    agency_name,
    COUNT(*) AS headcount,
    ROUND(AVG(annual), 0) AS avg_annual,
    ROUND(MAX(annual), 0) AS max_annual
FROM employees
GROUP BY agency_name
HAVING COUNT(*) >= 100
ORDER BY avg_annual DESC
LIMIT 10;


-- each agency vs the overall average across agencies
SELECT
    agency_name,
    ROUND(avg_a, 0) AS agency_avg,
    ROUND(state_avg, 0) AS cross_agency_avg,
    ROUND(avg_a - state_avg, 0) AS diff_from_avg
FROM (
    SELECT
        agency_name,
        AVG(annual) AS avg_a,
        AVG(AVG(annual)) OVER () AS state_avg,
        COUNT(*) AS c
    FROM employees
    GROUP BY agency_name
    HAVING COUNT(*) >= 100
) t
ORDER BY diff_from_avg DESC
LIMIT 10;


-- overall gender pay gap
SELECT
    gender,
    COUNT(*) AS headcount,
    ROUND(AVG(annual), 0) AS avg_annual
FROM employees
WHERE gender IN ('MALE', 'FEMALE')
GROUP BY gender;


-- gender gap per agency (only where there are 50+ of each so it's not noise)
WITH gender_avg AS (
    SELECT agency_name, gender, AVG(annual) AS avg_a, COUNT(*) AS c
    FROM employees
    WHERE gender IN ('MALE', 'FEMALE')
    GROUP BY agency_name, gender
)
SELECT
    m.agency_name,
    ROUND(m.avg_a, 0) AS male_avg,
    ROUND(f.avg_a, 0) AS female_avg,
    ROUND(m.avg_a - f.avg_a, 0) AS gap,
    ROUND((m.avg_a - f.avg_a) / m.avg_a * 100, 1) AS gap_pct
FROM gender_avg m
JOIN gender_avg f ON m.agency_name = f.agency_name
WHERE m.gender = 'MALE' AND f.gender = 'FEMALE'
  AND m.c >= 50 AND f.c >= 50
ORDER BY gap_pct DESC
LIMIT 10;


-- highest paid job titles (20+ people so it's a real pay grade)
SELECT
    class_title,
    COUNT(*) AS holders,
    ROUND(AVG(annual), 0) AS avg_annual
FROM employees
GROUP BY class_title
HAVING COUNT(*) >= 20
ORDER BY avg_annual DESC
LIMIT 10;


-- top earner in each agency
SELECT agency_name, class_title, annual, rnk
FROM (
    SELECT
        agency_name,
        class_title,
        annual,
        RANK() OVER (PARTITION BY agency_name ORDER BY annual DESC) AS rnk
    FROM employees
) ranked
WHERE rnk = 1
ORDER BY annual DESC
LIMIT 10;


-- salary band distribution + share of workforce
SELECT
    CASE
        WHEN annual <  30000 THEN 'A: <30k'
        WHEN annual <  50000 THEN 'B: 30-50k'
        WHEN annual <  75000 THEN 'C: 50-75k'
        WHEN annual < 100000 THEN 'D: 75-100k'
        ELSE 'E: 100k+'
    END AS salary_band,
    COUNT(*) AS headcount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_workforce
FROM employees
GROUP BY salary_band
ORDER BY salary_band;


-- representation and pay by ethnicity
SELECT
    ethnicity,
    COUNT(*) AS headcount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct,
    ROUND(AVG(annual), 0) AS avg_annual
FROM employees
GROUP BY ethnicity
ORDER BY headcount DESC;


-- does pay go up with tenure (hire date vs 2016 reference year)
SELECT
    CASE
        WHEN tenure_yrs <  5 THEN '0-4 yrs'
        WHEN tenure_yrs < 10 THEN '5-9 yrs'
        WHEN tenure_yrs < 20 THEN '10-19 yrs'
        ELSE '20+ yrs'
    END AS tenure_band,
    COUNT(*) AS headcount,
    ROUND(AVG(annual), 0) AS avg_annual
FROM (
    SELECT annual, TIMESTAMPDIFF(YEAR, employ_date, '2016-01-01') AS tenure_yrs
    FROM employees
    WHERE employ_date IS NOT NULL
) t
GROUP BY tenure_band
ORDER BY avg_annual;


-- pay quartiles inside the 5 biggest agencies
SELECT
    q.agency_name,
    q.quartile,
    COUNT(*) AS staff,
    ROUND(MIN(q.annual), 0) AS band_floor,
    ROUND(MAX(q.annual), 0) AS band_ceiling
FROM (
    SELECT
        e.agency_name,
        e.annual,
        NTILE(4) OVER (PARTITION BY e.agency_name ORDER BY e.annual) AS quartile
    FROM employees e
    JOIN (
        SELECT agency_name
        FROM employees
        GROUP BY agency_name
        ORDER BY COUNT(*) DESC
        LIMIT 5
    ) top5 ON e.agency_name = top5.agency_name
) q
GROUP BY q.agency_name, q.quartile
ORDER BY q.agency_name, q.quartile;


-- how many people earn above their own agency's average
-- (started with a correlated subquery but it timed out on 149k rows,
--  window function version below runs in ~1s)
SELECT agency_name, COUNT(*) AS above_avg_earners
FROM (
    SELECT agency_name, annual,
           AVG(annual) OVER (PARTITION BY agency_name) AS agency_avg
    FROM employees
) t
WHERE annual > agency_avg
GROUP BY agency_name
ORDER BY above_avg_earners DESC
LIMIT 10;


-- full-time vs part-time pay
SELECT
    CASE
        WHEN status LIKE '%FULL-TIME%' THEN 'Full-time'
        WHEN status LIKE '%PART-TIME%' THEN 'Part-time'
        ELSE 'Other'
    END AS work_type,
    COUNT(*) AS headcount,
    ROUND(AVG(annual), 0) AS avg_annual,
    ROUND(AVG(hrs_per_wk), 1) AS avg_hours
FROM employees
GROUP BY work_type
ORDER BY headcount DESC;

-- which job titles work the most hours per week
SELECT
    class_title,
    COUNT(*) AS holders,
    ROUND(AVG(hrs_per_wk), 1) AS avg_hours,
    ROUND(AVG(annual), 0) AS avg_annual
FROM employees
GROUP BY class_title
HAVING COUNT(*) >= 20
ORDER BY avg_hours DESC
LIMIT 10;


-- which agencies work the most hours on average
SELECT
    agency_name,
    COUNT(*) AS headcount,
    ROUND(AVG(hrs_per_wk), 1) AS avg_hours
FROM employees
GROUP BY agency_name
HAVING COUNT(*) >= 100
ORDER BY avg_hours DESC
LIMIT 10;


-- high pay for low hours: best paid roles working under 40 hrs/wk
SELECT
    class_title,
    ROUND(AVG(hrs_per_wk), 1) AS avg_hours,
    ROUND(AVG(annual), 0) AS avg_annual
FROM employees
GROUP BY class_title
HAVING COUNT(*) >= 20 AND AVG(hrs_per_wk) < 40
ORDER BY avg_annual DESC
LIMIT 10;
