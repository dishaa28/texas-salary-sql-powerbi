"""
prepare_data.py
---------------
Cleans the raw Texas State Employee Salary export (salary.csv) into a tidy
salary_clean.csv ready to load into MySQL.

What it does:
  * keeps only the 15 analysis-relevant columns (drops empty metadata flags)
  * strips trailing whitespace the source pads every text field with
  * leaves dates as-is (mm/dd/yy); the SQL loader parses them with STR_TO_DATE

Usage:
    python prepare_data.py
"""

import pandas as pd

RAW_FILE   = "salary.csv"
CLEAN_FILE = "salary_clean.csv"

KEEP = [
    "AGENCY", "AGENCY NAME", "LAST NAME", "FIRST NAME",
    "CLASS CODE", "CLASS TITLE", "ETHNICITY", "GENDER", "STATUS",
    "EMPLOY DATE", "HRLY RATE", "HRS PER WK", "MONTHLY", "ANNUAL",
    "STATE NUMBER",
]


def main() -> None:
    df = pd.read_csv(RAW_FILE, low_memory=False)
    df = df[KEEP].copy()

    # The source pads every text column with spaces; trim them.
    text_cols = df.select_dtypes(include="object").columns
    for col in text_cols:
        df[col] = df[col].str.strip()

    df.to_csv(CLEAN_FILE, index=False)
    print(f"Wrote {CLEAN_FILE}: {df.shape[0]:,} rows x {df.shape[1]} columns")


if __name__ == "__main__":
    main()
