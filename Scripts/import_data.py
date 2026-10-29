import os
import pandas as pd
from sqlalchemy import create_engine, text

# Database Configuration (Environment variables se secure access)
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "password")  
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = "ecommerce_dw"

connection_uri = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(connection_uri)

def run_pipeline(file_path="Raw_data.csv"):
    # 1. EXTRACT
    print("[ETL] Ingesting raw transactional dataset...")
    df = pd.read_csv(file_path, encoding="ISO-8859-1")

    # 2. TRANSFORM & CLEANING
    print("[ETL] Cleaning and sanitizing records...")
    df.dropna(subset=["CustomerID", "InvoiceDate", "UnitPrice"], inplace=True)
    df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"], format="mixed", dayfirst=True)
    df["UnitPrice"] = df["UnitPrice"].astype(str).str.replace(",", "")
    df["UnitPrice"] = pd.to_numeric(df["UnitPrice"], errors="coerce")
    df["Quantity"] = pd.to_numeric(df["Quantity"], errors="coerce")
    
    # Filter cancellations and negative quantities
    df = df[df["Quantity"] > 0]
    df["CustomerID"] = df["CustomerID"].astype(int)

    # 3. STAGING LOAD
    print("[ETL] Staging cleaned data into MySQL (stg_ecommerce_raw)...")
    df.to_sql("stg_ecommerce_raw", con=engine, if_exists="replace", index=False)

    # 4. DIMENSIONAL POPULATION (KIMBALL STAR SCHEMA)
    print("[ETL] Populating Kimball Star Schema (Dimensions & Fact)...")
    with engine.connect() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))
        conn.execute(text("TRUNCATE TABLE fact_sales;"))
        conn.execute(text("TRUNCATE TABLE dim_customer;"))
        conn.execute(text("TRUNCATE TABLE dim_product;"))
        conn.execute(text("TRUNCATE TABLE dim_date;"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))

        # Populate Dim Customer
        conn.execute(text("""
            INSERT INTO dim_customer (customer_id, country)
            SELECT CustomerID, MAX(Country)
            FROM stg_ecommerce_raw
            WHERE CustomerID IS NOT NULL
            GROUP BY CustomerID;
        """))

        # Populate Dim Product
        conn.execute(text("""
            INSERT INTO dim_product (stock_code, description, unit_price)
            SELECT StockCode, MAX(Description), MAX(UnitPrice)
            FROM stg_ecommerce_raw
            GROUP BY StockCode;
        """))

        # Populate Dim Date
        conn.execute(text("""
            INSERT INTO dim_date (date_key, full_date, day_of_month, month_num, month_name, quarter, year)
            SELECT DISTINCT
                CAST(DATE_FORMAT(InvoiceDate, '%Y%m%d') AS UNSIGNED) AS date_key,
                DATE(InvoiceDate) AS full_date,
                DAY(InvoiceDate) AS day_of_month,
                MONTH(InvoiceDate) AS month_num,
                MONTHNAME(InvoiceDate) AS month_name,
                QUARTER(InvoiceDate) AS quarter,
                YEAR(InvoiceDate) AS year
            FROM stg_ecommerce_raw
            WHERE InvoiceDate IS NOT NULL;
        """))

        # Populate Fact Sales
        conn.execute(text("""
            INSERT INTO fact_sales (invoice_no, customer_key, product_key, date_key, quantity, unit_price)
            SELECT 
                r.InvoiceNo,
                c.customer_key,
                p.product_key,
                CAST(DATE_FORMAT(r.InvoiceDate, '%Y%m%d') AS UNSIGNED) AS date_key,
                r.Quantity,
                r.UnitPrice
            FROM stg_ecommerce_raw r
            JOIN dim_product p ON r.StockCode = p.stock_code
            LEFT JOIN dim_customer c ON r.CustomerID = c.customer_id;
        """))

        conn.commit()

    print("[ETL] Pipeline executed successfully. Star schema populated.")

if __name__ == "__main__":
    run_pipeline()