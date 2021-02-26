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



