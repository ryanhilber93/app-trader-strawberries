/* 
Ideas to get started:
work on unioning the tables
profit, revenue, and cost equations
some apps are different prices in different tables
make columns that represent if it is in one table or both
*/
/*
Revenue = 2500m
Cost = 10000(price) + 1000m
Profit = 1500m - 10000 for price < 1
Profit = 1500m - 10000(price) for price >= 1
Where 0 < m < 12(1+2(rating))
Max profit will occure at the max m value bc profit equation is always increasing
Finding profit at max m value finds the total profit over the life of the app
Profit = 1500(12(1+2(rating))) - 10000 for price < 1
Profit = 1500(12(1+2(rating))) - 10000(price) for price < 1
*/
-- to find expected profit from app store
SELECT name, price, rating, CAST(review_count AS numeric) AS cleaned_review_count,
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END as expected_profit
FROM app_store_apps
ORDER BY expected_profit DESC, cleaned_review_count DESC;

-- to find expected profit from google store
SELECT name, price, rating, review_count,
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END as expected_profit
FROM play_store_apps
WHERE rating IS NOT null
ORDER BY expected_profit DESC, review_count DESC

-- to clean price
SELECT CAST(TRIM(REPLACE(price, '$', '')) AS numeric) AS cleaned_price
FROM play_store_apps

/* Joshua's with subquery:
SELECT c.name, c.cleaned_price AS clean_price, c.rating, c.review_count,
CASE WHEN c.cleaned_price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * c.cleaned_price END as expected_profit
FROM
	(SELECT name,
	 		CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS cleaned_price,
	 		rating,
	 		review_count
	FROM play_store_apps
	WHERE rating IS NOT NULL) AS c
ORDER BY expected_profit DESC, c.review_count DESC;
*/
-- compare based on content rating (1b from slides)
