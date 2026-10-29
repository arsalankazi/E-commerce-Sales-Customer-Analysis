USE ecommerce_dw;

-- 1. Month-over-Month (MoM) Revenue Growth Trend
WITH MonthlyRevenue AS (
    SELECT 
        d.year,
        d.month_num,
        d.month_name,
        SUM(f.total_amount) AS revenue
    FROM fact_sales f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.year, d.month_num, d.month_name
)
SELECT 
    year,
    month_name,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY year, month_num) AS prev_month_revenue,
    ROUND(((revenue - LAG(revenue, 1) OVER (ORDER BY year, month_num)) / 
           LAG(revenue, 1) OVER (ORDER BY year, month_num)) * 100, 2) AS mom_growth_pct
FROM MonthlyRevenue;

-- 2. Customer RFM Segmentation via NTILE(4) Window Functions
WITH CustomerAggregates AS (
    SELECT 
        c.customer_id,
        DATEDIFF('2011-12-09', MAX(d.full_date)) AS recency,
        COUNT(DISTINCT f.invoice_no) AS frequency,
        SUM(f.total_amount) AS monetary
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_key = c.customer_key
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY c.customer_id
),
RFMScores AS (
    SELECT 
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM CustomerAggregates
)
SELECT 
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE 
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champion'
        WHEN f_score >= 3 AND m_score >= 3 THEN 'Loyal Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Standard'
    END AS customer_segment
FROM RFMScores;