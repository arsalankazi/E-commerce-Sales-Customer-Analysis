# 🛒 E-commerce Sales & Customer Analysis

## 📌 Project Overview
An end-to-end Data Analytics project analyzing **5.4 lakh+ rows** of real-world e-commerce transactional data. The goal was to identify revenue drivers, understand customer purchasing behavior, and provide actionable business recommendations to improve retention and profitability.

## 🛠️ Tech Stack
- **Database:** MySQL (RDBMS)
- **Programming:** Python (Pandas, SQLAlchemy, PyMySQL)
- **Visualization:** Power BI
- **Automation:** Windows Task Scheduler

## 🔄 Data Pipeline (ETL Process)
1. **Extract:** Loaded raw CSV data using Python Pandas with `ISO-8859-1` encoding to handle special characters.
2. **Transform:** 
   - Handled missing `CustomerID` values (blank strings → NULL).
   - Standardized mixed date formats using `pd.to_datetime`.
   - Removed negative quantities (Returns/Refunds).
3. **Load:** Loaded cleaned data into MySQL staging table (`raw_data`).
4. **Normalize:** Broke down flat CSV into **4 relational tables** (Customers, Products, Orders, OrderDetails) using SQL.
5. **Automate:** Configured Windows Task Scheduler to run the ETL pipeline daily at midnight.

## 📊 Database Schema (Normalized)
- **Customers:** 4,339 records
- **Products:** 3,665 records
- **Orders:** 18,536 records
- **OrderDetails:** 387,875 records

## 📈 Key Business Insights
- **Top Products:** The top 10 products generate a significant portion of total revenue. `PAPER CRAFT, LITTLE BIRDIE` is the highest-selling item (80K+ units).
- **Seasonality:** Sales peak massively in November-December (Holiday season). Power BI forecast predicts continued growth.
- **Customer Value (80/20 Rule):** A small group of VIP customers contributes a massive share of revenue. The top 10 customers alone account for over ₹70 Lakhs in spending.
- **Geographical Revenue:** The United Kingdom is the primary market contributing **68.13%** of revenue, followed by Germany (14.62%) and France (10.91%).
- **RFM Segmentation:** Using SQL Window Functions (`NTILE(4)`), customers were segmented into 'Champions' (R=4, F=4, M=4) and 'Lost' segments.

## 💡 Recommendations
1. **VIP Loyalty Program:** Launch a premium loyalty program for the 'Champion' RFM segment to ensure retention and increase Customer Lifetime Value (CLV).
2. **Inventory Management:** Ensure high stock levels for top 10 products before peak seasons (Nov-Dec) to avoid stockouts.
3. **Targeted Marketing:** Stop spending on 'Lost' customers (R=1) and reallocate that budget to 'At Risk' customers who bought frequently but haven't purchased recently.
4. **International Expansion:** Increase localized marketing efforts in Germany and France, which are strong secondary markets.

## 📂 Repository Structure

E-commerce-Sales-Customer-Analysis

1) Scripts:
 import_data.py             # Python ETL Script
 run_etl.bat                # Automation Script
 
2) SQL:
 ecommerce_analysis.sql     # SQL Queries
 
3) PowerBI
 Dashboard.pbix             # Power BI File
 
4) Screenshots:
  Executive_Summary.png
  Marketing_View.png
  Operations_View.png
  
5) README.md
