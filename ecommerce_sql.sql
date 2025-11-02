create database ecommerce;

select * from ecommerce_data_cleaned;

alter table ecommerce_data_cleaned
drop MyUnknownColumn;


--- Business Questions ---

--- 1. How much total net revenue did we generate each year? ---

SELECT 
    Purchase_Year,
    ROUND(SUM(Net_Amount), 2) AS total_revenue
FROM ecommerce_data_cleaned
GROUP BY Purchase_year
ORDER BY Purchase_year;

--- 2. Which product categories bring in the highest total revenue? ---

SELECT 
    Product_Category,
    ROUND(SUM(Net_Amount), 2) AS total_revenue
FROM ecommerce_data_cleaned
GROUP BY Product_Category
ORDER BY total_revenue DESC
LIMIT 5;

--- 3. Do men or women spend more on average? ---

SELECT
    Gender,
    Product_Category,
    round(sum(Net_Amount),2) AS Total_Net_Amount,
    round(Avg(Net_Amount),2) AS Avg_Net_Amount
FROM
    ecommerce_data_cleaned
GROUP BY
    Gender, Product_Category
ORDER BY
    Gender, Total_Net_Amount DESC;


--- 4. Who are our highest-spending customers? ---

SELECT 
    CID,
    ROUND(SUM(Net_Amount), 2) AS total_spent,
    COUNT(TID) AS total_transactions
FROM ecommerce_data_cleaned
GROUP BY CID
ORDER BY total_spent DESC
LIMIT 10;

--- 5. What percentage of transactions used a discount? ---

SELECT 
    ROUND(
        (SUM(CASE WHEN DiscountAvailed = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS discount_usage_percentage
FROM ecommerce_data_cleaned;

--- 6. Which age group contributes the most to our revenue? ---

SELECT 
    Age_Group,
    ROUND(SUM(Net_Amount), 2) AS total_revenue,
    COUNT(DISTINCT CID) AS total_customers
FROM ecommerce_data_cleaned
GROUP BY Age_Group
ORDER BY total_revenue DESC;

--- 7. How has cumulative revenue grown month-by-month? ---

WITH monthly_sales AS (
    SELECT 
        Purchase_Month AS month_no,
        Purchase_Month_Name AS month,
        ROUND(SUM(Net_Amount),2) AS monthly_revenue
    FROM ecommerce_data_cleaned
    GROUP BY month_no,month
)
SELECT 
    month_no,
    month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month),2) AS cumulative_revenue
FROM monthly_sales
ORDER BY month_no;

--- 8. Who are our top customers ranked by total spend? ---

WITH customer_spend AS (
    SELECT 
        CID,
        ROUND(SUM(Net_Amount),2) AS total_spent
    FROM ecommerce_data_cleaned
    GROUP BY CID
)
SELECT 
    CID,
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_spend
ORDER BY spending_rank
LIMIT 10;

--- 9. What’s the best-selling product category in each location? ---
WITH category_sales AS (
    SELECT 
        Location,
        Product_Category,
        ROUND(SUM(Net_Amount),2) AS total_sales
    FROM ecommerce_data_cleaned
    GROUP BY Location, Product_Category
),
CTE AS (
    SELECT 
        Location,
        Product_Category,
        total_sales,
        RANK() OVER (PARTITION BY Location ORDER BY total_sales DESC) AS rank_in_location
    FROM category_sales
)
SELECT 
    Location,
    Product_Category,
    total_sales,
    rank_in_location
FROM CTE
WHERE rank_in_location = 1;

--- 10. Has each customer’s spending increased or decreased over time?

WITH customer_time_spend AS (
    SELECT 
        CID,
        EXTRACT(YEAR FROM Purchase_Date) AS year,
        SUM(Net_Amount) AS yearly_spend
    FROM ecommerce_data_cleaned
    GROUP BY CID, year
)
SELECT 
    CID,
    year,
    yearly_spend,
    COALESCE(LAG(yearly_spend) OVER (PARTITION BY CID ORDER BY year), 0) AS previous_year_spend,
    yearly_spend - COALESCE(LAG(yearly_spend) OVER (PARTITION BY CID ORDER BY year), 0) AS change_in_spend
FROM customer_time_spend
ORDER BY CID, year;

--- 11. Which products rely most heavily on discounts?

WITH discount_stats AS (
    SELECT 
        Product_Category,
        ROUND(AVG((Discount_Amount/Gross_Amount) * 100), 2) AS avg_discount_percentage
    FROM ecommerce_data_cleaned
    WHERE Discount_Amount > 0
    GROUP BY Product_Category
)
SELECT 
    Product_Category,
    avg_discount_percentage,
    RANK() OVER (ORDER BY avg_discount_percentage DESC) AS discount_rank
FROM discount_stats;


--- 12. What percentage of total revenue does each product category contribute? ---

WITH category_sales AS (
    SELECT 
        Product_Category,
        ROUND(SUM(Net_Amount),2) AS total_sales
    FROM ecommerce_data_cleaned
    GROUP BY Product_Category
)
SELECT 
    Product_Category,
    total_sales,
    ROUND(
        (total_sales * 100.0 / SUM(total_sales) OVER ()), 2
    ) AS revenue_share_percentage
FROM category_sales
ORDER BY revenue_share_percentage DESC;



