use ecommerce_analysis;

-- STEP1
CREATE TABLE raw_data (
    InvoiceNo VARCHAR(50),
    StockCode VARCHAR(50),
    Description VARCHAR(255),
    Quantity VARCHAR(50),
    InvoiceDate VARCHAR(50),
    UnitPrice VARCHAR(50),
    CustomerID VARCHAR(50),
    Country VARCHAR(100)
);

select * from raw_data;
select count(*) from raw_data;

-- STEP2
-- data formatge fixing
ALTER TABLE raw_data MODIFY CustomerID INT;
ALTER TABLE raw_data MODIFY Quantity INT;
ALTER TABLE raw_data MODIFY UnitPrice DECIMAL(10,2);
UPDATE raw_data SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%d-%m-%Y %H:%i');
ALTER TABLE raw_data MODIFY InvoiceDate DATETIME;
DELETE FROM raw_data WHERE Quantity <= 0;
UPDATE raw_data SET UnitPrice = 0.00 WHERE UnitPrice IS NULL;

-- STEP3 
-- Normalization means breaking raw data table into 4 small tables
-- CUSTOMERS TABLE
INSERT INTO Customers (CustomerID, Country)
SELECT CustomerID, MAX(Country) 
FROM raw_data 
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;

-- Products
INSERT INTO Products (StockCode, Description, UnitPrice)
SELECT StockCode, MAX(Description), MAX(UnitPrice) 
FROM raw_data 
GROUP BY StockCode;

-- Orders
INSERT INTO Orders (InvoiceNo, CustomerID, InvoiceDate)
SELECT InvoiceNo, MAX(CustomerID), MAX(InvoiceDate) 
FROM raw_data 
GROUP BY InvoiceNo;

-- OrderDetails
INSERT INTO OrderDetails (InvoiceNo, StockCode, Quantity)
SELECT InvoiceNo, StockCode, SUM(Quantity) 
FROM raw_data 
GROUP BY InvoiceNo, StockCode;

-- Business Questions
-- top 10 selling products
SELECT p.Description, SUM(od.Quantity) AS TotalSold
FROM OrderDetails od
JOIN Products p ON od.StockCode = p.StockCode
GROUP BY p.Description
ORDER BY TotalSold DESC
LIMIT 10;

-- month over month sales growth
WITH MonthlySales AS (
    SELECT DATE_FORMAT(o.InvoiceDate, '%Y-%m') AS Month, 
           SUM(od.Quantity * p.UnitPrice) AS Revenue
    FROM Orders o
    JOIN OrderDetails od ON o.InvoiceNo = od.InvoiceNo
    JOIN Products p ON od.StockCode = p.StockCode
    GROUP BY DATE_FORMAT(o.InvoiceDate, '%Y-%m')
)
SELECT Month, Revenue, 
       LAG(Revenue) OVER (ORDER BY Month) AS PrevMonthRevenue,
       (Revenue - LAG(Revenue) OVER (ORDER BY Month)) AS Growth
FROM MonthlySales;



 -- Top 10 Customers by Revenue 
SELECT o.CustomerID, SUM(od.Quantity * p.UnitPrice) AS TotalSpent
FROM Orders o
JOIN OrderDetails od ON o.InvoiceNo = od.InvoiceNo
JOIN Products p ON od.StockCode = p.StockCode
GROUP BY o.CustomerID
ORDER BY TotalSpent DESC
LIMIT 10;

-- Country-wise Revenue Contribution
SELECT c.Country, SUM(od.Quantity * p.UnitPrice) AS Revenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.InvoiceNo = od.InvoiceNo
JOIN Products p ON od.StockCode = p.StockCode
GROUP BY c.Country
HAVING Revenue > 10000
ORDER BY Revenue DESC;

-- Advanced SQL (RFM Analysis) 
WITH CustomerRFM AS (
    SELECT 
        o.CustomerID,
        DATEDIFF('2011-12-09', MAX(o.InvoiceDate)) AS Recency,
        COUNT(DISTINCT o.InvoiceNo) AS Frequency,
        SUM(od.Quantity * p.UnitPrice) AS Monetary
    FROM Orders o
    JOIN OrderDetails od ON o.InvoiceNo = od.InvoiceNo
    JOIN Products p ON od.StockCode = p.StockCode
    GROUP BY o.CustomerID
)
SELECT 
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score,
    NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Score,
    NTILE(4) OVER (ORDER BY Monetary ASC) AS M_Score
FROM CustomerRFM;


SELECT COUNT(*) FROM Customers;    
SELECT COUNT(*) FROM Products;     
SELECT COUNT(*) FROM Orders;       
SELECT COUNT(*) FROM OrderDetails; 


