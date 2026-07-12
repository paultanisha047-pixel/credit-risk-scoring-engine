

# load_raw.py
# -----------
# Reads raw CSVs from local disk and loads them into DuckDB as tables.
# This runs ONCE before dbt — dbt reads directly from DuckDB tables.
# DuckDB handles 2.2M rows efficiently on 8GB RAM by streaming
# rather than loading everything into memory at once.

import duckdb
import os

# ── Config ────────────────────────────────────────────────────
# DuckDB creates this file automatically if it doesn't exist
DB_PATH = "data/credit_risk.duckdb"

# Local paths to raw CSVs downloaded from Kaggle
LC_PATH = os.path.expanduser(
    "~/credit-risk-data/lending-club/accepted_2007_to_2018Q4.csv"
)
HC_PATH = os.path.expanduser(
    "~/credit-risk-data/home-credit/application_train.csv"
)

# ── Connect ───────────────────────────────────────────────────
con = duckdb.connect(DB_PATH)
print(f"Connected to DuckDB at {DB_PATH} ✅")

# ── Load Lending Club ─────────────────────────────────────────
# read_csv_auto infers column types automatically
# sample_size=10000 means DuckDB inspects 10k rows to infer types
# ignore_errors=true skips malformed rows instead of crashing
print("Loading Lending Club CSV into DuckDB...")
con.execute(f"""
    CREATE OR REPLACE TABLE raw_loans AS
    SELECT * FROM read_csv_auto('{LC_PATH}',
        header=true,
        sample_size=10000,
        ignore_errors=true
    )
""")

lc_count = con.execute("SELECT COUNT(*) FROM raw_loans").fetchone()[0]
print(f"raw_loans loaded — {lc_count:,} rows ✅")

# ── Load Home Credit ──────────────────────────────────────────
# Stress test dataset — used in Phase 4 out-of-sample validation
# Only application_train.csv needed — contains borrower features + target
print("Loading Home Credit CSV into DuckDB...")
con.execute(f"""
    CREATE OR REPLACE TABLE home_credit_raw AS
    SELECT * FROM read_csv_auto('{HC_PATH}',
        header=true,
        sample_size=10000,
        ignore_errors=true
    )
""")

hc_count = con.execute("SELECT COUNT(*) FROM home_credit_raw").fetchone()[0]
print(f"home_credit_raw loaded — {hc_count:,} rows ✅")

# ── Verify ────────────────────────────────────────────────────
tables = con.execute("SHOW TABLES").fetchall()
print("\nTables in DuckDB:")
for t in tables:
    print(f"  → {t[0]}")

con.close()
print("\nDone — DuckDB ready for dbt ✅")