USE ecommerce_dw;

-- 1. Populate Dim Customer
INSERT INTO dim_customer (customer_id, country)
SELECT CustomerID, MAX(Country)
FROM stg_ecommerce_raw
WHERE CustomerID IS NOT NULL AND Quantity > 0
GROUP BY CustomerID;

-- 2. Populate Dim Product
INSERT INTO dim_product (stock_code, description, unit_price)
SELECT StockCode, MAX(Description), MAX(UnitPrice)
FROM stg_ecommerce_raw
WHERE Quantity > 0
GROUP BY StockCode;

-- 3. Populate Dim Date
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

-- 4. Populate Fact Sales
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
LEFT JOIN dim_customer c ON r.CustomerID = c.customer_id
WHERE r.Quantity > 0;