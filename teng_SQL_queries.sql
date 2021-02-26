--Just looking at the tables. Apple 1st, then Google. 
SELECT *
FROM app_store_apps;

SELECT *
FROM play_store_apps;

--Code from Ryan Hilber, Apple store profit
/*
Revenue = 2500m
Cost = 10000(price) + 1000m
Profit = 1500m - 10000 for price < 1
Profit = 1500m - 1000(price) for price >= 1
Where 0 < m < 12(1+2(rating))
Max profit will occure at the max m value bc profit equation is always increasing
Finding profit at max m value finds the total profit over the life of the app
Profit = 1500(12(1+2(rating))) - 10000 for price < 1
Profit = 1500(12(1+2(rating))) - 10000(price) for price < 1
*/

SELECT name, price, rating, primary_genre,
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END as expected_revenue
FROM app_store_apps
ORDER BY expected_revenue DESC;

--Code from Ryan Hilber, Google profit
SELECT Distinct name, price, rating,
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END as expected_revenue
FROM play_store_apps
WHERE rating IS NOT null
ORDER BY expected_revenue DESC, rating;

--Code from Josh, similar to Ryan but with subquery
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

--Code from Josh, counting the duplicate names. 
SELECT name,
	Count(name) AS name_count
FROM play_store_apps
GROUP BY name
ORDER BY name_count DESC;

--Code from Josh, Big O' Union
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

--From Ryan, Intersecting both tables to show top expected profit for apps in both stores.
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


--Need to dig into genres. Apple store 1st, then Google
--Top genres per expected revenue then review count.
SELECT primary_genre, 'Apple Store' AS store,
	SUM (CASE 
		WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
		ELSE 1500*(12*(1+2*rating)) - 10000 * price 
	END) as expected_profit
FROM app_store_apps
GROUP BY primary_genre
UNION ALL
SELECT genres, 'Google Play' AS store,
	SUM(CASE 
		WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
		WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) 
	END) as expected_profit
FROM play_store_apps
WHERE rating IS NOT null
GROUP BY genres
ORDER BY expected_profit DESC;

--Diving into the apps from the top genres, using CTE
WITH top_genres(genre_name,store,expected_profit) AS
(
	SELECT primary_genre, 'Apple Store' AS store,
		SUM (CASE 
			WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
			ELSE 1500*(12*(1+2*rating)) - 10000 * price 
		END) as expected_profit
	FROM app_store_apps
	GROUP BY primary_genre
	UNION
	SELECT genres, 'Google Play' AS store,
		SUM(CASE 
			WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
			WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) 
		END) as expected_profit
	FROM play_store_apps
	WHERE rating IS NOT null
	GROUP BY genres
	ORDER BY expected_profit DESC
	LIMIT 10)

SELECT distinct a.name, a.primary_genre,
	CASE WHEN a.price < 1 THEN 1500*(12*(1+2*a.rating)) - 10000 
	ELSE 1500*(12*(1+2*a.rating)) - 10000 * a.price END as expected_profit
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
USING(name)
WHERE primary_genre IN (
	SELECT distinct genre_name
	FROM top_genres)
ORDER BY expected_profit DESC;