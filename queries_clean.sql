-- Cleaner queries

-- Total expected profit table from all apps in both stores
SELECT DISTINCT a.name, a.primary_genre, p.genres, (CAST(a.review_count AS numeric) + p.review_count) AS total_review_count,
(2500*(12*(1+2*a.rating)) + 2500*(12*(1+2*ROUND(2 * p.rating) / 2))) -
	CASE WHEN a.price < 1 THEN 10000 ELSE 10000 * a.price END -
	CASE WHEN CAST(TRIM(REPLACE(p.price, '$', '')) AS numeric) < 1 THEN 10000 ELSE 10000 * CAST(TRIM(REPLACE(p.price, '$', '')) AS numeric) END -
	1000 * 
	CASE WHEN 12*(1+2*a.rating) > 12*(1+2*ROUND(2 * p.rating) / 2) THEN 12*(1+2*a.rating)
	ELSE 12*(1+2*ROUND(2 * p.rating) / 2) END AS total_expected_profit
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name
ORDER BY total_expected_profit DESC, total_review_count DESC;

-- Expected profit by content rating app store
SELECT content_rating, COUNT(content_rating), AVG(rating) AS avg_rating, AVG(
CASE WHEN price < 1 THEN 1500*(12*(1+2*rating)) - 10000 
ELSE 1500*(12*(1+2*rating)) - 10000 * price END) as avg_expected_profit
FROM app_store_apps
WHERE name IN 
	(SELECT name
	FROM app_store_apps
	INTERSECT
	SELECT name
	FROM play_store_apps)
GROUP BY content_rating
ORDER BY avg_expected_profit DESC;

-- Expected profit by content rating google store
SELECT content_rating, COUNT(content_rating), AVG(rating), AVG(
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END) as avg_expected_profit
FROM play_store_apps
WHERE name IN 
	(SELECT name
	FROM app_store_apps
	INTERSECT
	SELECT name
	FROM play_store_apps)
GROUP BY content_rating
ORDER BY avg_expected_profit DESC;

-- Best apps by content rating apple
WITH p AS(
	SELECT name, content_rating, review_count,
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
	SELECT name, content_rating, expected_profit, review_count, ROW_NUMBER() OVER(PARTITION BY content_rating ORDER BY expected_profit DESC, CAST(review_count AS numeric) DESC) AS profit_rank
	FROM p
	GROUP BY name, content_rating, expected_profit, review_count)
SELECT p.name, p.content_rating, r.expected_profit, r.profit_rank, p.review_count
FROM p
INNER JOIN r
ON p.name = r.name
WHERE profit_rank <=3
ORDER BY content_rating, profit_rank, CAST(p.review_count AS numeric) DESC;

-- Best apps by content rating play
WITH p AS(
	SELECT DISTINCT name, content_rating, review_count,
	CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(ROUND(2 * rating) / 2 AS numeric))) - 10000
	WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(ROUND(2 * rating) / 2 AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END as expected_profit
	FROM play_store_apps
	WHERE name IN 
		(SELECT name
		FROM app_store_apps
		INTERSECT
		SELECT name
		FROM play_store_apps)
	ORDER BY expected_profit DESC),
r AS(
	SELECT DISTINCT name, content_rating, expected_profit, review_count, ROW_NUMBER() OVER(PARTITION BY content_rating ORDER BY expected_profit DESC, review_count DESC) AS profit_rank
	FROM p
	GROUP BY name, content_rating, expected_profit, review_count)
SELECT p.name, p.content_rating, r.expected_profit, r.profit_rank, r.review_count
FROM p
INNER JOIN r
ON p.name = r.name
WHERE profit_rank <=10
ORDER BY content_rating, profit_rank, r.review_count DESC; 
