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

--From Ryan, new math 
SELECT DISTINCT a.name, 
(2500*(12*(1+2*a.rating)) + 2500*(12*(1+2*ROUND(2 * p.rating) / 2))) -
	CASE WHEN a.price < 1 THEN 10000 ELSE 10000 * a.price END -
	CASE WHEN CAST(TRIM(REPLACE(p.price, '$', '')) AS numeric) < 1 THEN 10000 ELSE 10000 * CAST(TRIM(REPLACE(p.price, '$', '')) AS numeric) END -
	1000 * 
	CASE WHEN 12*(1+2*a.rating) > 12*(1+2*ROUND(2 * p.rating) / 2) THEN 12*(1+2*a.rating)
	ELSE 12*(1+2*ROUND(2 * p.rating) / 2) END AS total_expected_profit
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name
ORDER BY total_expected_profit DESC;

--FROM Josh, expected profits stored in CTE
WITH a AS(
	SELECT name,
			price,
			rating,
			primary_genre AS genre,
			CAST(review_count AS int) AS review_count,
			CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
			ELSE 1500*(12*(1+2*rating)) - 10000 * price END AS expected_profit
	FROM app_store_apps
	),
p AS(
	SELECT c.name AS name,
			c.clean_price AS price,
			c.clean_rating AS rating,
			c.genres AS genre,
			c.review_count AS review_count,
			CASE WHEN c.clean_price < 1 THEN 1500*(12*(1+2*c.clean_rating)) - 10000 
			ELSE 1500*(12*(1+2*c.clean_rating)) - 10000 * c.clean_price
			END as expected_profit
	FROM
		(SELECT name,
	 			CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS clean_price,
	 			COALESCE(ROUND(ROUND(2*rating,0)/2,1),0) AS clean_rating,
		 		genres,
	 			review_count
		FROM play_store_apps
		) AS c
	)
SELECT a.name, a.genre,
		a.expected_profit + p.expected_profit + 1000*(12*(1+2*least(a.rating,p.rating))) AS total_exp_profit
FROM a
INNER JOIN p
USING (name)
ORDER BY total_exp_profit DESC;

--From Ryan, filering by rank
WITH p AS(
	SELECT name, content_rating,
	CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * price END as expected_profit
	FROM app_store_apps
	WHERE name IN 
		(SELECT name
		FROM app_store_apps
		INTERSECT
		SELECT name
		FROM play_store_apps)
	ORDER BY expected_profit DESC),
r AS(
	SELECT name, content_rating, expected_profit, ROW_NUMBER() OVER(PARTITION BY content_rating ORDER BY expected_profit DESC) AS profit_rank
	FROM p
	GROUP BY name, content_rating, expected_profit
	)
SELECT p.name, p.content_rating, r.expected_profit, r.profit_rank
FROM p
INNER JOIN r
ON p.name = r.name
WHERE profit_rank <=3
ORDER BY content_rating, profit_rank;

--Need to redo the math part, learning how to do this. Hints(above) from code from teammates 
Select distinct name, primary_genre, 
	--revenue calc
	2500*12*(1+2*a.rating) +
	2500*12*(1+2*g.rating) AS revenue,
	--cost calc
	CASE WHEN a.price < 1 THEN 10000 + 1000 
		ELSE a.price * 10000 + 1000 
	END 
	+
	CASE WHEN CAST(TRIM(REPLACE(g.price,'$',''))AS numeric) < 1 THEN 10000 + 1000
		ELSE CAST(TRIM(REPLACE(g.price,'$',''))AS numeric) * 10000 + 1000
	END AS cost,
	--expected profit
	2500*12*(1+2*a.rating) +
	2500*12*(1+2*g.rating) -
	CASE WHEN a.price < 1 THEN 10000 + 1000 
		ELSE a.price * 10000 + 1000 
	END 
	+
	CASE WHEN CAST(TRIM(REPLACE(g.price,'$',''))AS numeric) < 1 THEN 10000 + 1000
		ELSE CAST(TRIM(REPLACE(g.price,'$',''))AS numeric) * 10000 + 1000
	END AS expected_profit
--Joining the shared apps from both	
FROM app_store_apps AS a
INNER JOIN play_store_apps AS g
Using (name)
ORDER BY expected_profit DESC;

--Pulling my genre code from earlier and using new profit formula. Gonna try out Josh's CTE. THIS IS WITH SUM
WITH a AS(
	SELECT name,
			price,
			rating,
			primary_genre AS genre,
			CAST(review_count AS int) AS review_count,
			CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
			ELSE 1500*(12*(1+2*rating)) - 10000 * price END AS expected_profit
	FROM app_store_apps
	),
	
	p AS(
	SELECT c.name AS name,
			c.clean_price AS price,
			c.clean_rating AS rating,
			c.genres AS genre,
			c.review_count AS review_count,
			CASE WHEN c.clean_price < 1 THEN 1500*(12*(1+2*c.clean_rating)) - 10000 
			ELSE 1500*(12*(1+2*c.clean_rating)) - 10000 * c.clean_price
			END as expected_profit
	FROM
		(SELECT name,
	 			CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS clean_price,
	 			COALESCE(ROUND(ROUND(2*rating,0)/2,1),0) AS clean_rating,
		 		genres,
	 			review_count
		FROM play_store_apps
		) AS c
	)


/*
This union gives genre with highest expected profits as a whole. Note that it is likely skewed towards genre with most apps. 
I tried AVG instead but then that skews it towards genre that have only a few entries.
*/

--I can wrap the below as a subquery to drill down to apps only in the top genres
SELECT 'Apple Store' AS store, genre,
		SUM(expected_profit) as expected_profit
	FROM a
	GROUP BY genre

	UNION ALL

	SELECT 'Google Play' AS store, genre,
		SUM(expected_profit) as expected_profit
	FROM p
	GROUP BY genre
	ORDER BY expected_profit DESC;

--Genre by AVG PROFIT 
WITH a AS(
	SELECT primary_genre,
		ROUND(AVG(CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * price END),0) apple_expected_profit
	FROM app_store_apps
	GROUP BY primary_genre
		HAVING COUNT(name) >100
	ORDER BY apple_expected_profit DESC
	LIMIT 10),
	
	g AS(
	SELECT genres,
		ROUND(AVG(CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) END),0) google_expected_profit
	FROM play_store_apps
	GROUP BY genres
		HAVING COUNT(name) >100
	ORDER BY google_expected_profit DESC
	LIMIT 10)
	
SELECT 'Apple Store' AS Store,primary_genre,
		ROUND(AVG(CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * price END),0) expected_profit
	FROM app_store_apps
	GROUP BY primary_genre
		HAVING COUNT(name) >100
UNION ALL
SELECT 'Google Store' AS Store,genres,
		ROUND(AVG(CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) END),0) expected_profit
	FROM play_store_apps
	GROUP BY genres
		HAVING COUNT(name) >100
	ORDER BY expected_profit DESC
	LIMIT 100
/*
SELECT name, primary_genre, ROUND((CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * price END),0) apple_expected_profit
FROM app_store_apps
WHERE primary_genre IN (SELECT primary_genre
					   FROM a)
UNION ALL
SELECT name, genres, ROUND((CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) END),0) google_expected_profit
FROM play_store_apps
WHERE genres IN (SELECT genres
					   FROM g);					   
*/
--Retrying the ranking differently, the above code seems to not work well. Not working at all!
WITH p AS(
	SELECT name, primary_genre,
	CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
	ELSE 1500*(12*(1+2*rating)) - 10000 * price END as expected_profit
	FROM app_store_apps
	WHERE name IN 
		(SELECT name
		FROM app_store_apps
		INTERSECT
		SELECT name
		FROM play_store_apps)
	ORDER BY expected_profit DESC),
r AS(
	SELECT name, primary_genre, expected_profit, ROW_NUMBER() OVER(PARTITION BY primary_genre ORDER BY expected_profit DESC) AS profit_rank
	FROM p
	GROUP BY name, primary_genre, expected_profit
	)
SELECT p.name, p.primary_genre, r.expected_profit, r.profit_rank
FROM p
INNER JOIN r
ON p.name = r.name
WHERE profit_rank <=3
ORDER BY primary_genre, profit_rank;