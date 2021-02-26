
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


