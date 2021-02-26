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

Revenue for shared app that we own both of = 2500m.apple + 2500m.play
Cost = (app store cost) + (play store cost) + 1000m.max
m is calculated same as previous analysis but can be different between google and apple

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

-- app store

SELECT content_rating, COUNT(content_rating), AVG(
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END) as avg_expected_profit
FROM app_store_apps
GROUP BY content_rating
ORDER BY avg_expected_profit DESC;

-- google store
SELECT content_rating, COUNT(content_rating), AVG(
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END) as avg_expected_profit
FROM play_store_apps
GROUP BY content_rating
ORDER BY avg_expected_profit DESC;

-- app store
SELECT content_rating, COUNT(content_rating), AVG(rating) AS avg_rating, AVG(
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END) as avg_expected_profit
FROM app_store_apps
GROUP BY content_rating
ORDER BY avg_expected_profit DESC;

-- google store
SELECT content_rating, COUNT(content_rating), AVG(rating), AVG(
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END) as avg_expected_profit
FROM play_store_apps
GROUP BY content_rating
ORDER BY avg_expected_profit DESC;

-- to find expected profit from app store - edit to only include names in both tables
SELECT name, price, rating, primary_genre, CAST(review_count AS numeric) AS cleaned_review_count,
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END as expected_profit
FROM app_store_apps
WHERE name IN 
	(SELECT name
	FROM app_store_apps
	INTERSECT
	SELECT name
	FROM play_store_apps)
ORDER BY expected_profit DESC, cleaned_review_count DESC;

-- google store
SELECT name, price, rating, review_count,
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END as expected_profit
FROM play_store_apps
WHERE rating IS NOT null AND name IN
		(SELECT name
		FROM app_store_apps
		INTERSECT
		SELECT name
		FROM play_store_apps)
ORDER BY expected_profit DESC, review_count DESC

SELECT name
FROM app_store_apps
INTERSECT
SELECT name
FROM play_store_apps

--Joshua's code to get whole big table:
SELECT name,
		'Google Play' AS store,
		CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS cleaned_price,
		review_count,
		rating,
		content_rating,
		genres
FROM play_store_apps
UNION ALL
SELECT name,
		'Apple Store' AS store,
		price,
		CAST(review_count AS int),
		rating,
		content_rating,
		primary_genre
FROM app_store_apps;

-- to find expected profit from app store - edit to only include names in both tables - edit to include rating for each
SELECT a.name, a.rating, p.rating, CAST(a.review_count AS numeric) AS cleaned_review_count,
CASE WHEN a.price < 1 THEN 1500*(12*(1+2*a.rating)) - 10000 
ELSE 1500*(12*(1+2*a.rating)) - 10000 * a.price END as expected_profit
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name
WHERE a.name IN 
	(SELECT name
	FROM app_store_apps
	INTERSECT
	SELECT name
	FROM play_store_apps)
ORDER BY expected_profit DESC, cleaned_review_count DESC;

/* 
New profit for combination with answers from Mahesh
Revenue for shared app that we own both of = 2500m.apple + 2500m.play
Cost = (app store cost) + (play store cost) + 1000m.max
m is calculated same as previous analysis but can be different between google and apple
*/

SELECT a.name, (CAST(a.review_count AS numeric) + p.review_count) AS total_review_count,
2500*(12*(1+2*a.rating)) + 2500*(12*(1+2*ROUND(2 * p.rating / 2))) AS total_revenue,
	CASE WHEN a.price < 1 THEN 10000 ELSE 10000 * a.price +
	CASE WHEN p.price < 1 THEN 10000 ELSE 10000 * p.price +
	(1000 * 
	CASE WHEN 12*(1+2*a.rating) > 12*(1+2*ROUND(2 * p.rating / 2)) THEN 12*(1+2*a.rating)
	ELSE 12*(1+2*ROUND(2 * p.rating / 2)) END) AS total_cost,
total_revenue - total_cost AS total_profit
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name

SELECT a.name, (CAST(a.review_count AS numeric) + p.review_count) AS total_review_count
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name
