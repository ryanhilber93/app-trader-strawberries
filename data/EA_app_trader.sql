--General reference
SELECT *
FROM app_store_apps;

SELECT *
FROM play_store_apps;

--Union of the two tables with store field and other converted fields
COPY(
	SELECT name,
		'Google Play' AS store,
		CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS cleaned_price,
		review_count,
		rating,
		content_rating,
		genres
FROM play_store_apps
UNION 
SELECT name,
		'Apple Store' AS store,
		price,
		CAST(review_count AS int),
		rating,
		content_rating,
		primary_genre

FROM app_store_apps) To 'C\Users\yamar\Documents\NSS_Data_Analytics\projects\app-trader-strawberries\exported_query' DELIMITER ',' CSV HEADER;

--Expected profit for google_play_store_apps
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

--price and count for play_store_apps
SELECT c.cleaned_price,
		COUNT(c.cleaned_price) AS frequency
FROM
	(SELECT name,
	 		CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS cleaned_price,
	 		rating,
	 		review_count
	FROM play_store_apps
	WHERE rating IS NOT NULL) AS c
GROUP BY c.cleaned_price
ORDER BY c.cleaned_price DESC;

--price and count for app_store_apps
SELECT price,
		COUNT(price) AS frequency
FROM app_store_apps
GROUP BY price
ORDER BY price DESC;

--expected profit by price and count for app_store_apps (no bins)
SELECT price,
		COUNT(price) AS frequency,
		AVG(
			CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
		ELSE 1500*(12*(1+2*rating)) - 10000 * price END
			) AS avg_expected_profit
FROM app_store_apps
GROUP BY price
ORDER BY price DESC;

--expected profit by price and count for play_store_apps (no bins)

SELECT c.cleaned_price AS clean_price, 
		COUNT(c.cleaned_price) AS frequency,
		AVG(
			CASE WHEN c.cleaned_price < 1 THEN 1500*(12*(1+2*c.rating)) - 10000 
			ELSE 1500*(12*(1+2*c.rating)) - 10000 * c.cleaned_price END
			) AS avg_expected_profit
FROM
	(SELECT name,
	 		CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS cleaned_price,
	 		rating
	FROM play_store_apps
	WHERE rating IS NOT NULL) AS c
GROUP BY clean_price
ORDER BY clean_price DESC;

--Duplication Investigation
SELECT name,
		COUNT(name) AS name_count
FROM play_store_apps
GROUP BY name
ORDER BY name_count DESC;

--Rounding play_store_app ratings to half-values
SELECT rating,
		ROUND(ROUND(2*rating)/2,1) AS clean_rating
FROM play_store_apps;

------------------------------------------------------------------------------
--AVG Expected Profit by Content Rating (Ryan Hilber)
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

--Highest expected profit among apps common to both stores (v1)
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

--to Find the count of rows for applications found in either of the table .
SELECT COUNT(sub.name )
FROM
(
--Findinmg all applicateion in either of the table (counted once for the dup  nb 'UNION )
SELECT name,
		'Google Play' AS store,
		CAST(TRIM(REPLACE(price, '$', '')) AS numeric(5,2)) AS cleaned_price,
		review_count,
		rating,
		content_rating,
		genres
FROM play_store_apps
UNION 
SELECT name,
		'Apple Store' AS store,
		price,
		CAST(review_count AS int),
		rating,
		content_rating,
		primary_genre
	    FROM app_store_apps) AS sub ;
		
-----------------------------------------------------------------------------------------------------------------
/*Rounding a rating to the nearest multiple of .5 */

SELECT rating,
		ROUND(ROUND(2*rating)/2,1) AS clean_rating
FROM play_store_apps;

-----------------------Teng CTE---but the 1500 assumption was from orginal thought-------------------
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
WHERE primary_genre IN 
    (
	SELECT distinct genre_name,expected_profit
	FROM top_genres
	ORDER BY expected_profit DESC);

-------------------------------------Ryan's with 1500 changed (corrected !) As 2500 spent on each-------------
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

------------------------ Joshua CTE as follows---------------------------------
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
SELECT a.name,
		a.expected_profit + p.expected_profit + 1000*(12*(1+2*least(a.rating,p.rating))) AS total_exp_profit
FROM a
INNER JOIN p
USING (name)
ORDER BY total_exp_profit DESC;

----------------Ryan's Last suggestion to Rank the orders -------------------------
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
	GROUP BY name, content_rating, expected_profit)
SELECT p.name,p.content_rating, r.expected_profit, r.profit_rank
FROM p
INNER JOIN r
ON p.name = r.name
WHERE profit_rank <=3
ORDER BY content_rating, profit_rank;









































