select *
from app_store_apps;
select *
from play_store_apps;

***********


select ap.name, ap.price,pl.name,pl.price
from app_store_apps as ap
inner join play_store_apps as pl 
on ap.name = pl.name;


select a.name , a.primary_genre as app_primary_genre,  a.rating as app_rating, 
	   a.content_rating as app_content_rating,a.price as app_price,
       a.currency as app_currency,a.review_count as app_review_count 
	   from play_store_apps, b.review_count as play_review_count,
	   b.genres as play_genre, b.rating as play_rating,b.price as play_price,
	   b.content_rating as play_content_rating,b.type as play_type,b.install_count as play_install_count
	   from app_store_apps;
	   
	  SELECT CAST(TRIM(REPLACE(price, '$', '')) AS numeric) AS cleaned_price
FROM play_store_apps
 
****Ryan****
SELECT name, price, rating,
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END as expected_revenue
FROM play_store_apps
WHERE rating IS NOT null
ORDER BY expected_revenue DESC;


*******************Joshua*****************************************
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
**************Ryan***************************
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
*************Joshua************************
Rounding to half-values:
SELECT rating,
		ROUND(ROUND(2*rating)/2,1) AS clean_rating
FROM play_store_apps;
****************************************************8888*******

SELECT a.name as name , a.primary_genre as app_primary_genre,  a.rating as app_rating, 
	   a.content_rating as app_content_rating,a.price as app_price,
       a.currency as app_currency,a.review_count as app_review_count
	   from app_store_apps;
	   
	   
	   b.review_count as play_review_count,
	   b.genres as play_genre, b.rating as play_rating,b.price as play_price,
	   b.content_rating as play_content_rating,b.type as play_type,b.install_count as play_install_count;
 
 /* trying to see if there is some thing in install count and review count This is my part of the assignment*/
 
select distinct a.name, a.review_count::int, /*b.install_count,*/ max(b.review_count) as max_review_count , a.rating        
FROM app_store_apps a
inner join play_store_apps b
on a.name = b.name
group by a.name,a.review_count::int,a.rating
ORDER BY /*b.install_count desc,*/a.review_count::int desc, max_review_count desc,a.rating desc
 limit 10;
*********Teng *****
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
WHERE primary_genre IN;
**********************************Ryan  ****
SELECT DISTINCT a.name, (CAST(a.review_count AS numeric) + p.review_count) AS total_review_count,

(2500*(12*(1+2*a.rating)) + 2500*(12*(1+2*ROUND(2 * p.rating) / 2))) -
	CASE WHEN a.price < 1 THEN 10000 ELSE 10000 * a.price END -
	CASE WHEN CAST(TRIM(REPLACE(p.price, '$', '')) AS numeric) < 1 THEN 10000 ELSE 10000 * CAST(TRIM(REPLACE(p.price, '$', '')) AS numeric) END -
	1000 * 
	CASE WHEN 12*(1+2*a.rating) > 12*(1+2*ROUND(2 * p.rating) / 2) THEN 12*(1+2*a.rating)
	ELSE 12*(1+2*ROUND(2 * p.rating) / 2) END AS total_expected_profit
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name
ORDER BY total_expected_profit DESC;    /*Runs good*/
************************************************************
