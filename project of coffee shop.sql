use coffee_date;
select * from city;
select * from customers;
select * from sales;
select * from sales;
-- bussiness insight and data anaylist
-- q1Total Revenue from coffee sales
-- 	What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
    SUM(s.total) AS total_coffee_revenue
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN city ci
    ON c.city_id = ci.city_id
WHERE p.product_name LIKE '%Coffee%'
  AND YEAR(STR_TO_DATE(s.sale_date, '%d-%m-%Y')) = 2023
  AND QUARTER(STR_TO_DATE(s.sale_date, '%d-%m-%Y')) = 4;
  -- Q2 Sales Count for each product
 -- how many units of each coffee product have been sold?
 SELECT
    p.product_name,
    COUNT(s.sale_id) AS units_sold
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
WHERE p.product_name LIKE '%Coffee%'
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC;
-- q3 Average Sales amount per city
-- what is average sales amount per customer in each city?
SELECT
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    SUM(s.total) AS total_revenue,
    ROUND(
        SUM(s.total) / COUNT(DISTINCT s.customer_id),
        2
    ) AS avg_sales_per_customer
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN city ci
    ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY avg_sales_per_customer DESC
-- q4 City population and coffee consumers 
-- provide a list of cities along with populations and estimated coffee consumers?
 WITH city_coffee AS (
    SELECT
        city_name,
        population
    FROM city
)

SELECT
    city_name,
    population,
    ROUND(population * 0.25) AS estimated_coffee_consumers
FROM city_coffee
ORDER BY estimated_coffee_consumers DESC;
-- Q5 top selling products by city
-- what are the top 3 selling in each city based on sales volume?
WITH product_sales AS (
    SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS sales_volume
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY
        ci.city_name,
        p.product_name
),

ranked_products AS (
    SELECT
        city_name,
        product_name,
        sales_volume,
        ROW_NUMBER() OVER (
            PARTITION BY city_name
            ORDER BY sales_volume DESC, product_name
        ) AS ranking
    FROM product_sales
)

SELECT
    city_name,
    product_name,
    sales_volume,
    ranking
FROM ranked_products
WHERE ranking <= 3
ORDER BY city_name, ranking;
-- Q6 Customer segment by city 
-- How many unique customers are there in each city who have purchased coffee products?
SELECT
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN city ci
    ON c.city_id = ci.city_id
WHERE p.product_name LIKE '%Coffee%'
GROUP BY ci.city_name
ORDER BY unique_customers DESC;
-- Q7 average sales vs rent 
-- Find each city and their average sale per customer and avg rent per customer 
WITH city_analysis AS (
    SELECT
        ci.city_name,
        ci.estimated_rent,
        COUNT(DISTINCT c.customer_id) AS total_customers,
        SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY
        ci.city_name,
        ci.estimated_rent
)

SELECT
    city_name,
    total_customers,
    ROUND(total_sales / total_customers, 2)
        AS avg_sales_per_customer,
    estimated_rent,
    ROUND(estimated_rent / total_customers, 2)
        AS avg_rent_per_customer
FROM city_analysis
ORDER BY avg_sales_per_customer DESC;
	-- Q8  monthly sales growth
    -- sales growth rate: calculate the percentage growth (or decline) in sales over different time periods (monthly)
    -- each city?
    WITH monthly_sales AS (
    SELECT
        ci.city_name,
        DATE_FORMAT(
            STR_TO_DATE(s.sale_date, '%d-%m-%Y'),
            '%Y-%m'
        ) AS sales_month,
        SUM(s.total) AS current_month_sales

    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id

    GROUP BY
        ci.city_name,
        sales_month
),

sales_growth AS (
    SELECT
        city_name,
        sales_month,
        current_month_sales,

        LAG(current_month_sales) OVER (
            PARTITION BY city_name
            ORDER BY sales_month
        ) AS previous_month_sales

    FROM monthly_sales
)

SELECT
    city_name,
    sales_month,
    current_month_sales,
    previous_month_sales,

    ROUND(
        (current_month_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0) * 100,
        2
    ) AS growth_percentage

FROM sales_growth
ORDER BY
    city_name,
    sales_month;
	-- Q9Identify customer purchasing frequency in each city and segment customers based on their number of purchases.
    WITH customer_purchases AS (
    SELECT
        c.customer_id,
        ci.city_name,
        COUNT(s.sale_id) AS total_purchases
    FROM customers c
    JOIN city ci
        ON c.city_id = ci.city_id
    JOIN sales s
        ON c.customer_id = s.customer_id
    GROUP BY
        c.customer_id,
        ci.city_name
),

customer_segments AS (
    SELECT
        customer_id,
        city_name,
        total_purchases,
        CASE
            WHEN total_purchases = 1
                THEN 'One-Time Customer'
            WHEN total_purchases BETWEEN 2 AND 5
                THEN 'Occasional Customer'
            ELSE 'Frequent Customer'
        END AS customer_segment
    FROM customer_purchases
)

SELECT
    city_name,
    customer_segment,
    COUNT(customer_id) AS total_customers
FROM customer_segments
GROUP BY
    city_name,
    customer_segment
ORDER BY
    city_name,
    total_customers DESC;
   -- Q10 Identify which products contribute the most revenue in each city?
   WITH product_revenue AS (
    SELECT
        ci.city_name,
        p.product_name,
        SUM(s.total) AS total_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY
        ci.city_name,
        p.product_name
)

SELECT
    city_name,
    product_name,
    total_revenue,

    ROUND(
        total_revenue /
        SUM(total_revenue) OVER (
            PARTITION BY city_name
        ) * 100,
        2
    ) AS revenue_contribution_percentage

FROM product_revenue
ORDER BY
    city_name,
    revenue_contribution_percentage DESC;