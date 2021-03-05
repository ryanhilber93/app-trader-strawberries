--Data Exploration and Query Preparation----------------------------------------------------------------------------

--General reference
SELECT *
FROM app_store_apps;

SELECT *
FROM play_store_apps;

--Union of store databases with store field and other converted fields
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

--Duplication Investigation
SELECT name,
		COUNT(name) AS name_count
FROM play_store_apps
GROUP BY name
ORDER BY name_count DESC;

--Rounding play_store_app ratings to half-values
SELECT rating,
		ROUND(2*rating,0)/2 AS clean_rating
FROM play_store_apps;

--Expected profit for play_store_apps (Ryan Hilber)
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

--BOTTOM LINE: Top Apps According to Expected Profit

--Top Apps Common to Both Stores

WITH a AS(
	SELECT name,
			price,
			CASE WHEN price <= 1 THEN 'Free to $1.00'
				WHEN price < 3 THEN '$1.01 to $3.00'
				WHEN price < 5 THEN '$3.01 to $5.00'
				WHEN price < 10 THEN '$5.01 to $10.00'
				WHEN price < 20 THEN '$10.01 to $20.00'
				WHEN price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
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
			CASE WHEN c.clean_price <= 1 THEN 'Free to $1.00'
				WHEN c.clean_price < 3 THEN '$1.01 to $3.00'
				WHEN c.clean_price < 5 THEN '$3.01 to $5.00'
				WHEN c.clean_price < 10 THEN '$5.01 to $10.00'
				WHEN c.clean_price < 20 THEN '$10.01 to $20.00'
				WHEN c.clean_price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			c.clean_rating AS rating,
			c.genres AS genre,
			MAX(c.review_count) AS review_count,
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
	GROUP BY name, price, rating, genre, expected_profit
	)
SELECT a.name,
		a.price,
		p.price,
		a.genre,
		a.review_count + p.review_count AS total_review_count,
		a.expected_profit + p.expected_profit + 1000*(12*(1+2*least(a.rating,p.rating))) AS total_exp_profit
FROM a
INNER JOIN p
USING (name)
ORDER BY total_exp_profit DESC, total_review_count DESC;
	
--Top Apps Not Common to the Stores

WITH a AS(
	SELECT name,
			'Apple Store' AS store,
			price,
			CASE WHEN price <= 1 THEN 'Free to $1.00'
				WHEN price < 3 THEN '$1.01 to $3.00'
				WHEN price < 5 THEN '$3.01 to $5.00'
				WHEN price < 10 THEN '$5.01 to $10.00'
				WHEN price < 20 THEN '$10.01 to $20.00'
				WHEN price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			rating,
			primary_genre AS genre,
			CAST(review_count AS int) AS review_count,
			CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
			ELSE 1500*(12*(1+2*rating)) - 10000 * price END AS expected_profit
	FROM app_store_apps
	),
p AS(
	SELECT c.name AS name,
			'Play Store' AS store,
			c.clean_price AS price,
			CASE WHEN c.clean_price <= 1 THEN 'Free to $1.00'
				WHEN c.clean_price < 3 THEN '$1.01 to $3.00'
				WHEN c.clean_price < 5 THEN '$3.01 to $5.00'
				WHEN c.clean_price < 10 THEN '$5.01 to $10.00'
				WHEN c.clean_price < 20 THEN '$10.01 to $20.00'
				WHEN c.clean_price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			c.clean_rating AS rating,
			c.genres AS genre,
			MAX(c.review_count) AS review_count,
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
	GROUP BY name, price, rating, genre, expected_profit
	)
SELECT name,
		store,
		genre,
		review_count,
		expected_profit
FROM a
WHERE name NOT IN(
		SELECT name
		FROM p
		)
UNION 
SELECT name,
		store,
		genre,
		review_count,
		expected_profit
FROM p
WHERE name NOT IN(
		SELECT name
		FROM a)
ORDER BY expected_profit DESC, review_count DESC;

--Expected Profit by Price Investigations------------------------------------------------------------------------------

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

--Top Price Ranges by Store & for Apps Common to Both Stores-----------------------------------------------------------

--Top Price Ranges for App Store

WITH a AS(
	SELECT name,
			'Apple Store' AS store,
			price,
			CASE WHEN price <= 1 THEN 'Free to $1.00'
				WHEN price < 3 THEN '$1.01 to $3.00'
				WHEN price < 5 THEN '$3.01 to $5.00'
				WHEN price < 10 THEN '$5.01 to $10.00'
				WHEN price < 20 THEN '$10.01 to $20.00'
				WHEN price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			rating,
			primary_genre AS genre,
			CAST(review_count AS int) AS review_count,
			CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
			ELSE 1500*(12*(1+2*rating)) - 10000 * price END AS expected_profit
	FROM app_store_apps
	)
SELECT price_range,
		AVG(expected_profit) AS avg_exp_profit
FROM a
GROUP BY price_range
ORDER BY avg_exp_profit DESC;

--Top Price Ranges for Play Store

WITH p AS(
	SELECT c.name AS name,
			'Play Store' AS store,
			c.clean_price AS price,
			CASE WHEN c.clean_price <= 1 THEN 'Free to $1.00'
				WHEN c.clean_price < 3 THEN '$1.01 to $3.00'
				WHEN c.clean_price < 5 THEN '$3.01 to $5.00'
				WHEN c.clean_price < 10 THEN '$5.01 to $10.00'
				WHEN c.clean_price < 20 THEN '$10.01 to $20.00'
				WHEN c.clean_price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			c.clean_rating AS rating,
			c.genres AS genre,
			MAX(c.review_count) AS review_count,
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
	GROUP BY name, price, rating, genre, expected_profit
	)
SELECT price_range,
		AVG(expected_profit) AS avg_exp_profit
FROM p
GROUP BY price_range
ORDER BY avg_exp_profit DESC;

--Top Price Ranges for Apps Common to Both Stores
	
WITH a AS(
	SELECT name,
			price,
			CASE WHEN price <= 1 THEN 'Free to $1.00'
				WHEN price < 3 THEN '$1.01 to $3.00'
				WHEN price < 5 THEN '$3.01 to $5.00'
				WHEN price < 10 THEN '$5.01 to $10.00'
				WHEN price < 20 THEN '$10.01 to $20.00'
				WHEN price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
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
			CASE WHEN c.clean_price <= 1 THEN 'Free to $1.00'
				WHEN c.clean_price < 3 THEN '$1.01 to $3.00'
				WHEN c.clean_price < 5 THEN '$3.01 to $5.00'
				WHEN c.clean_price < 10 THEN '$5.01 to $10.00'
				WHEN c.clean_price < 20 THEN '$10.01 to $20.00'
				WHEN c.clean_price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			c.clean_rating AS rating,
			c.genres AS genre,
			MAX(c.review_count) AS review_count,
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
	GROUP BY name, price, rating, genre, expected_profit
	)
SELECT price_range,
		COUNT(price_range) AS frequency,
		AVG(a.expected_profit + p.expected_profit + 1000*(12*(1+2*least(a.rating,p.rating)))) AS avg_exp_profit
FROM a
INNER JOIN p
USING (name, price, price_range)
GROUP BY price_range
ORDER BY avg_exp_profit DESC;

--Top Apps Common to Both Stores by Rank in Price Range

WITH a AS(
	SELECT name,
			price,
			CASE WHEN price <= 1 THEN 'Free to $1.00'
				WHEN price < 3 THEN '$1.01 to $3.00'
				WHEN price < 5 THEN '$3.01 to $5.00'
				WHEN price < 10 THEN '$5.01 to $10.00'
				WHEN price < 20 THEN '$10.01 to $20.00'
				WHEN price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
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
			CASE WHEN c.clean_price <= 1 THEN 'Free to $1.00'
				WHEN c.clean_price < 3 THEN '$1.01 to $3.00'
				WHEN c.clean_price < 5 THEN '$3.01 to $5.00'
				WHEN c.clean_price < 10 THEN '$5.01 to $10.00'
				WHEN c.clean_price < 20 THEN '$10.01 to $20.00'
				WHEN c.clean_price < 50 THEN '$20.00 to $50.00'
				ELSE 'Over $50' END AS price_range,
			c.clean_rating AS rating,
			c.genres AS genre,
			MAX(c.review_count) AS review_count,
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
	GROUP BY name, price, rating, genre, expected_profit
	),
r AS (
	SELECT name,
		p.review_count,
		price_range,
		AVG(a.expected_profit + p.expected_profit + 1000*(12*(1+2*least(a.rating,p.rating)))) AS avg_exp_profit,
		RANK() OVER(PARTITION BY price_range 
					ORDER BY AVG(a.expected_profit + p.expected_profit + 1000*(12*(1+2*least(a.rating,p.rating)))) DESC
				   ) AS rank_in_range
	FROM a
	INNER JOIN p
	USING (name, price, price_range)
	GROUP BY name, price_range, p.review_count
	ORDER BY avg_exp_profit DESC
	)
SELECT name,
		price_range,
		avg_exp_profit,
		rank_in_range,
		review_count
FROM r
WHERE rank_in_range <= 3;
	
----------------------------------------------------------------------------------------------------------------------


