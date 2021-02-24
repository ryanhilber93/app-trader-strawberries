SELECT *
FROM app_store_apps;

SELECT *
FROM play_store_apps;

/*SELECT name,
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
FROM app_store_apps Replace(price, '$', '')*/



--Expected profit for play_store_apps
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

SELECT c.cleaned_price,
		COUNT(c.cleaned_price) AS frequency
FROM app_store_apps
GROUP BY c.cleaned_price
ORDER BY c.cleaned_price DESC;

/* AVG Expected Profit by Content Rating (Ryan Hilber)

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
*/