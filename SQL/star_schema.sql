-- ============================================================================
-- Enterprise E-Commerce Data Warehouse (OLAP)
-- Dimensional Model: Kimball Star Schema
-- Database: MySQL 8.0+
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ecommerce_dw;
USE ecommerce_dw;

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS stg_ecommerce_raw;

-- 1. STAGING TABLE (Raw Ingestion Layer)
CREATE TABLE stg_ecommerce_raw (
    InvoiceNo VARCHAR(50),
    StockCode VARCHAR(50),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(100)
);

-- 2. DIMENSION TABLES
CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    country VARCHAR(100) NOT NULL,
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB;

CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    stock_code VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    unit_price DECIMAL(10,2),
    INDEX idx_stock_code (stock_code)
) ENGINE=InnoDB;

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_month INT NOT NULL,
    month_num INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
) ENGINE=InnoDB;

-- 3. FACT TABLE (Central Grain: 1 Row per Ordered Item)
CREATE TABLE fact_sales (
    sales_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) NOT NULL,
    customer_key INT,
    product_key INT NOT NULL,
    date_key INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    CONSTRAINT fk_sales_product FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    CONSTRAINT fk_sales_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    
    INDEX idx_date_key (date_key),
    INDEX idx_customer_key (customer_key)
) ENGINE=InnoDB;