select *
from app_store_apps;
select *
from play_store_apps;

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
 

SELECT name, price, rating,
CASE WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) < 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000
WHEN CAST(TRIM(REPLACE(price, '$', '')) AS numeric) >= 1 THEN 1500*(12*(1+2*CAST(rating AS numeric))) - 10000 * CAST(TRIM(REPLACE(price, '$', '')) AS numeric) END as expected_revenue
FROM play_store_apps
WHERE rating IS NOT null
ORDER BY expected_revenue DESC;
WITH psa AS (SELECT DISTINCT name AS psa_name, category, price AS psa_price,rating AS psa_rating,
			 review_count AS psa_review_count
		  	 FROM play_store_apps
	 		 WHERE rating > 4
				AND price::money < 1:: money
				AND review_count > 100000
				AND category ILIKE 'Game'),
	 asa AS (SELECT DISTINCT name AS asa_name, primary_genre AS category , price AS asa_price,
			 rating AS asa_rating, review_count AS asa_review_count
	  		 FROM app_store_apps
  	  		 WHERE rating > 4
				AND price::money < 1:: money
				AND review_count::numeric > 100000
	 			AND primary_genre ILIKE 'Games');
 