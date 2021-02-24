--Just looking at the tables. Apple 1st, then Google. 
SELECT *
FROM app_store_apps;

SELECT *
FROM play_store_apps;

--Code from Ryan Hilber
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

SELECT name, price, rating,
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END as expected_revenue
FROM app_store_apps
ORDER BY expected_revenue DESC;

--Code from Ryan Hilber
SELECT name, price, rating,
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

--Need to dig into genres. Apple store 1st, then Google
SELECT primary_genre, SUM(review_count::int) AS sum_review_count,
	SUM (CASE 
		WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
		ELSE 1500*(12*(1+2*rating)) - 10000 * price 
	END) as expected_revenue
FROM app_store_apps
GROUP BY primary_genre
ORDER BY expected_revenue DESC, SUM(review_count::int) DESC;

SELECT genres, SUM(review_count::int) AS sum_review_count,
	SUM(CASE 
		WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
		WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) 
	END) as expected_revenue
FROM play_store_apps
WHERE rating IS NOT null
GROUP BY genres
ORDER BY expected_revenue DESC, SUM(review_count::int) DESC;
