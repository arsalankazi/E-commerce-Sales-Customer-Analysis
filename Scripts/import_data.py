import pandas as pd
from sqlalchemy import create_engine, text


# 1. EXTRACT: Load the CSV file.

file_path = "Raw_data.csv"
print("Data is loading...")
df = pd.read_csv(file_path, encoding='ISO-8859-1')


# 2. TRANSFORM: Data Cleaning

print("Cleaning data...")
df.dropna(subset=['CustomerID', 'InvoiceDate', 'UnitPrice'], inplace=True)
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'], format='mixed', dayfirst=True)
df['UnitPrice'] = df['UnitPrice'].astype(str).str.replace(',', '')
df['UnitPrice'] = pd.to_numeric(df['UnitPrice'], errors='coerce')
df['Quantity'] = pd.to_numeric(df['Quantity'], errors='coerce')
df = df[df['Quantity'] > 0]
df['CustomerID'] = df['CustomerID'].astype(int)


# 3. LOAD: raw_data table me daalo

engine = create_engine('mysql+pymysql://root:%23%2405Sept2003@localhost:3306/ecommerce_analysis')

print("Data is importing into the MySQL...")
df.to_sql('raw_data', con=engine, if_exists='replace', index=False)


# 4. NORMALIZE: Insert data into all 4 tables.

print("Normalizing data into 4 tables...")
with engine.connect() as conn:

    # Turn OFF the Foreign Key checks.
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
    
    # Clean the old data from all the tables to avoid duplications.

    conn.execute(text("TRUNCATE TABLE OrderDetails"))
    conn.execute(text("TRUNCATE TABLE Orders"))
    conn.execute(text("TRUNCATE TABLE Products"))
    conn.execute(text("TRUNCATE TABLE Customers"))
    
    # Turn ON the Foreign Key checks.
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
    
    # Customers table
    conn.execute(text("""
        INSERT INTO Customers (CustomerID, Country)
        SELECT CustomerID, MAX(Country) 
        FROM raw_data 
        WHERE CustomerID IS NOT NULL
        GROUP BY CustomerID
    """))
    
    # Products table
    conn.execute(text("""
        INSERT INTO Products (StockCode, Description, UnitPrice)
        SELECT StockCode, MAX(Description), MAX(UnitPrice) 
        FROM raw_data 
        GROUP BY StockCode
    """))
    
    # Orders table
    conn.execute(text("""
        INSERT INTO Orders (InvoiceNo, CustomerID, InvoiceDate)
        SELECT InvoiceNo, MAX(CustomerID), MAX(InvoiceDate) 
        FROM raw_data 
        GROUP BY InvoiceNo
    """))
    
    # OrderDetails table
    conn.execute(text("""
        INSERT INTO OrderDetails (InvoiceNo, StockCode, Quantity)
        SELECT InvoiceNo, StockCode, SUM(Quantity) 
        FROM raw_data 
        GROUP BY InvoiceNo, StockCode
    """))
    
    conn.commit()

print("ETL + Normalization completed successfully!")