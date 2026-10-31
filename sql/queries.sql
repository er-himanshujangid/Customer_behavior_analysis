-- Query 1: Look at the data
SELECT * FROM customers LIMIT 5;

-- Query 2: Choose columns
SELECT customer_id, item_purchased, purchase_amount_usd
FROM customers
LIMIT 5;

-- Query 3: Filter with WHERE
SELECT COUNT(*) FROM customers
WHERE category = 'Clothing';

-- Query 4: Filter with two conditions
SELECT COUNT(*) FROM customers
WHERE category = 'Clothing' AND season = 'Winter';

-- Query 5: Sort the highest purchases
SELECT customer_id, item_purchased, purchase_amount_usd
FROM customers
ORDER BY purchase_amount_usd DESC, customer_id
LIMIT 3;

-- Query 6: Count by group
SELECT gender, COUNT(*) AS customers
FROM customers
GROUP BY gender;

-- Aggregations, GROUP BY and HAVING

-- Query 1: Overall numbers
SELECT SUM(purchase_amount_usd)         AS total_revenue,
       ROUND(AVG(purchase_amount_usd), 2) AS avg_purchase,
       MIN(purchase_amount_usd)         AS lowest,
       MAX(purchase_amount_usd)         AS highest
FROM customers;

-- Query 2: Category summary
SELECT category,
       COUNT(*)                          AS purchases,
       SUM(purchase_amount_usd)          AS revenue,
       ROUND(AVG(purchase_amount_usd), 2) AS avg_purchase
FROM customers
GROUP BY category
ORDER BY revenue DESC;

-- Query 3: Group by two columns
SELECT season, category, SUM(purchase_amount_usd) AS revenue
FROM customers
GROUP BY season, category
ORDER BY revenue DESC
LIMIT 3;

-- Query 4: Filter groups with HAVING
SELECT location, SUM(purchase_amount_usd) AS revenue
FROM customers
GROUP BY location
HAVING SUM(purchase_amount_usd) > 5500
ORDER BY revenue DESC;

-- Query 5: Compare subscribers
SELECT subscription_status,
       COUNT(*) AS customers,
       ROUND(AVG(purchase_amount_usd), 2) AS avg_purchase
FROM customers
GROUP BY subscription_status;

--- Query 6 : Customers and average purchase by age group.
SELECT age_group,
       COUNT(customer_id)                 AS customers,
       ROUND(AVG(purchase_amount_usd), 2) AS avg_purchase
FROM customers
GROUP BY age_group
ORDER BY avg_purchase DESC;

-- CASE WHEN and your first CTE

-- Query 1: Label each review rating
SELECT customer_id,
       review_rating,
       CASE
           WHEN review_rating >= 4.5 THEN 'Excellent'
           WHEN review_rating >= 3.5 THEN 'Good'
           ELSE 'Needs improvement'
       END AS rating_label
FROM customers
ORDER BY customer_id
LIMIT 5;

-- Query 2: Count customers per rating label
WITH labeled AS (
    SELECT customer_id,
           purchase_amount_usd,
           CASE
               WHEN review_rating >= 4.5 THEN 'Excellent'
               WHEN review_rating >= 3.5 THEN 'Good'
               ELSE 'Needs improvement'
           END AS rating_label
    FROM customers
)
SELECT rating_label,
       COUNT(*) AS customers,
       ROUND(AVG(purchase_amount_usd), 2) AS avg_purchase
FROM labeled
GROUP BY rating_label
ORDER BY customers DESC;

-- Query 3: Each category’s share of revenue
WITH cat AS (
    SELECT category, SUM(purchase_amount_usd) AS revenue
    FROM customers
    GROUP BY category
)
SELECT category,
       revenue,
       ROUND(revenue * 100.0 / (SELECT SUM(revenue) FROM cat), 1) AS pct_of_total
FROM cat
ORDER BY revenue DESC;

-- Query 4: Discount rate by category
SELECT category,
       COUNT(*) AS purchases,
       ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_discounted
FROM customers
GROUP BY category
ORDER BY pct_discounted DESC;

-- Window functions

-- Query 1: Rank categories by revenue
SELECT category,
       SUM(purchase_amount_usd) AS revenue,
       RANK() OVER (ORDER BY SUM(purchase_amount_usd) DESC) AS revenue_rank
FROM customers
GROUP BY category;

-- Query 2: Revenue share without a subquery
SELECT category,
       SUM(purchase_amount_usd) AS revenue,
       ROUND(100.0 * SUM(purchase_amount_usd) / SUM(SUM(purchase_amount_usd)) OVER (), 1) AS pct_of_total
FROM customers
GROUP BY category
ORDER BY revenue DESC;

-- Query 3: Top 2 purchases in each category
WITH ranked AS (
    SELECT category, customer_id, item_purchased, purchase_amount_usd,
           ROW_NUMBER() OVER (
               PARTITION BY category
               ORDER BY purchase_amount_usd DESC, customer_id
           ) AS rn
    FROM customers
)
SELECT category, customer_id, item_purchased, purchase_amount_usd, rn
FROM ranked
WHERE rn <= 2
ORDER BY category, rn;

-- Query 4: Compare each category to the overall average
SELECT category,
       ROUND(AVG(purchase_amount_usd), 2) AS avg_purchase,
       ROUND(AVG(AVG(purchase_amount_usd)) OVER (), 2) AS avg_of_category_averages
FROM customers
GROUP BY category;

