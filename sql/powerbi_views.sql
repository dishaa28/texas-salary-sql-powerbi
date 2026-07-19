USE texas_salary;

-- =====================================================
-- Power BI Views for Texas Salary Dashboard
-- =====================================================

-- VIEW 1: KPI cards (single-row summary)
CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT
    COUNT(*) AS total_employees,
    COUNT(DISTINCT agency_name) AS total_agencies,
    COUNT(DISTINCT class_title) AS total_job_titles,
    ROUND(AVG(annual), 0) AS avg_annual_salary,
    ROUND(MAX(annual), 0) AS max_annual_salary,
    ROUND(SUM(annual), 0) AS total_payroll
FROM employees;


-- VIEW 2: Top paying agencies (100+ staff)
CREATE OR REPLACE VIEW vw_agency_pay AS
SELECT
    agency_name,
    COUNT(*) AS headcount,
    ROUND(AVG(annual), 0) AS avg_annual,
    ROUND(MAX(annual), 0) AS max_annual
FROM employees
GROUP BY agency_name
HAVING COUNT(*) >= 100;
-- note: no LIMIT here — pull all qualifying agencies,
-- use Power BI's Top N filter on the visual instead


-- VIEW 3: Gender pay gap by agency (50+ each gender)
CREATE OR REPLACE VIEW vw_gender_gap AS
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
  AND m.c >= 50 AND f.c >= 50;


-- VIEW 4: Salary band distribution
CREATE OR REPLACE VIEW vw_salary_bands AS
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
GROUP BY salary_band;


-- VIEW 5: Ethnicity representation & pay
CREATE OR REPLACE VIEW vw_ethnicity_pay AS
SELECT
    ethnicity,
    COUNT(*) AS headcount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_workforce,
    ROUND(AVG(annual), 0) AS avg_annual
FROM employees
GROUP BY ethnicity;


-- VIEW 6: Tenure vs pay (sort fix baked in)
CREATE OR REPLACE VIEW vw_tenure_pay AS
SELECT
    CASE
        WHEN tenure_yrs <  5 THEN 'A: 0-4 yrs'
        WHEN tenure_yrs < 10 THEN 'B: 5-9 yrs'
        WHEN tenure_yrs < 20 THEN 'C: 10-19 yrs'
        ELSE 'D: 20+ yrs'
    END AS tenure_band,
    COUNT(*) AS headcount,
    ROUND(AVG(annual), 0) AS avg_annual
FROM (
    SELECT annual, TIMESTAMPDIFF(YEAR, employ_date, '2016-01-01') AS tenure_yrs
    FROM employees
    WHERE employ_date IS NOT NULL
) t
GROUP BY tenure_band;

SHOW FULL TABLES IN texas_salary WHERE TABLE_TYPE = 'VIEW';
SELECT * FROM vw_kpi_summary;
SELECT * FROM vw_salary_bands ORDER BY salary_band;
SELECT * FROM vw_tenure_pay ORDER BY tenure_band;
SELECT * FROM vw_gender_gap ORDER BY gap_pct DESC LIMIT 5;