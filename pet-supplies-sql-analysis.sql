-- Importing CSV File
CREATE TABLE pet_supplies (
    product_id INTEGER,
    category TEXT,
    animal TEXT,
    size TEXT,
    price NUMERIC(10,2),
    sales NUMERIC(10,2),
    rating INTEGER,
    repeat_purchase INTEGER
);

COPY pet_supplies
FROM 'C:\Users\Public\pet_supplies.csv'
DELIMITER ','
CSV HEADER;


-- Data Summary 
SELECT 
	COUNT(product_id) AS total_products, 
	ROUND(AVG(price)::NUMERIC, 2) AS avg_product_price,
	ROUND(SUM(sales)::NUMERIC, 2) AS total_revenue, 
	ROUND(AVG(rating)::NUMERIC, 2) AS avg_rating,
	ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_purchase_rate_pct
FROM pet_supplies;


-- Query 1
-- Revenue and Repeat Purchase Rate by Category
SELECT 
	category, 
	ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
	ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales_per_product, 
	ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_rate_pct
FROM pet_supplies
GROUP BY category
ORDER BY total_sales DESC; 


-- Query 2
-- Animal vs. Size Breakdown
SELECT 
	animal,
	size, 
	COUNT(product_id) AS product_count,
	ROUND(AVG(price)::NUMERIC, 2) AS avg_price,
	ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales
FROM pet_supplies
WHERE animal != 'Unknown' and size != 'Unknown'
GROUP BY animal, size 
ORDER BY animal, 
	CASE size 
		WHEN 'Small' THEN 1 
		WHEN 'Medium' THEN 2 
		WHEN 'Large' THEN 3
		ELSE 4
	END; 


-- Query 3
-- Top 3 Revenue Drivers per Animal Type
WITH RankedProducts AS (
    SELECT 
        product_id,
        category,
        animal,
        sales,
        rating,
        DENSE_RANK() OVER (
            PARTITION BY animal 
            ORDER BY sales DESC
        ) AS sales_rank
    FROM pet_supplies
    WHERE animal != 'Unknown'
)

SELECT 
    animal,
    sales_rank,
    product_id,
    category,
    sales,
    rating
FROM RankedProducts
WHERE sales_rank <= 3
ORDER BY animal, sales_rank;


-- Query 4
-- Rating Cohort Segmentation vs. Customer Retention
SELECT 
	CASE 
		WHEN rating = 0 THEN '0 (Unrated)'
		WHEN rating BETWEEN 1 AND 4 THEN 'Low (1-4)'
		WHEN rating BETWEEN 5 AND 7 THEN 'Mid (5-7)'
		ELSE 'High (8-10)'
	END AS rating_tier, 
	COUNT(product_id) AS total_items, 
	ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales, 
	ROUND(100.0 * SUM(repeat_purchase) / COUNT(product_id), 2) AS repeat_purchase_pct
FROM pet_supplies
GROUP BY 1
ORDER BY MIN(rating);


-- Query 5
-- Products Outperforming Their Category Averages
SELECT 
	product_id,
    category,
    sales,
    ROUND(AVG(sales) OVER(PARTITION BY category)::NUMERIC, 2) AS category_avg_sales,
    ROUND((sales - AVG(sales) OVER(PARTITION BY category))::NUMERIC, 2) AS variance_from_category_avg
FROM pet_supplies
WHERE sales > (
    SELECT AVG(p2.sales) 
    FROM pet_supplies p2 
    WHERE p2.category = pet_supplies.category
)
ORDER BY variance_from_category_avg DESC
LIMIT 10;