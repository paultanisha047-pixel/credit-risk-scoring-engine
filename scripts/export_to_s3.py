import duckdb
import boto3
import os
from dotenv import load_dotenv

# -- Force load_dotenv to look specifically in the current root directory ----
dotenv_path = os.path.join(os.getcwd(), '.env')
load_dotenv(dotenv_path=dotenv_path)

AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
BUCKET = os.getenv('S3_BUCKET')
DB_PATH = 'data/credit_risk.duckdb'

# -- Safety Guard: Check if environmental variables are loaded properly ----
missing_vars = []
if not AWS_ACCESS_KEY: missing_vars.append("AWS_ACCESS_KEY_ID")
if not AWS_SECRET_KEY: missing_vars.append("AWS_SECRET_ACCESS_KEY")
if not BUCKET: missing_vars.append("S3_BUCKET")

if missing_vars:
    print(f"❌ ERROR: Could not find or read these keys in your .env file: {', '.join(missing_vars)}")
    print(f"Looking for .env at: {os.path.abspath(dotenv_path)}")
    print("Please check that your .env file exists and isn't accidentally named '.env.txt'")
    exit(1)

# -- Connect to DuckDB ----------------------------------------------------
print('Connected to DuckDB ✅')
con = duckdb.connect(DB_PATH)

row_count = con.execute('SELECT COUNT(*) FROM fct_loans').fetchone()[0]
train_count = con.execute('SELECT COUNT(*) FROM fct_loans WHERE is_train = true').fetchone()[0]
test_count = con.execute('SELECT COUNT(*) FROM fct_loans WHERE is_train = false').fetchone()[0]

print(f'fct_loans total : {row_count:,} rows')
print(f'Training set    : {train_count:,} rows')
print(f'Test set        : {test_count:,} rows')

# -- Export Data ----------------------------------------------------------
print('Exporting fct_loans to parquet...')
con.execute("COPY (SELECT * FROM fct_loans) TO 'data/fct_loans.parquet' (FORMAT PARQUET)")
print('Exported to data/fct_loans.parquet ✅')
con.close()

# -- Upload to S3 ---------------------------------------------------------
print('Uploading to S3...')
s3 = boto3.client('s3', aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
s3.upload_file('data/fct_loans.parquet', BUCKET, 'processed/fct_loans.parquet')
print('Uploaded to S3 successfully! ✅')