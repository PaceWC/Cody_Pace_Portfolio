#Full Project #1 - World Life Expectancy Data (Data cleaning)

#View all files in the table
SELECT * FROM world_life_expectancy.world_life_expectancy;

#Findout if we have duplicate data
SELECT country, year, CONCAT(country, year), COUNT(CONCAT(country, year))
FROM world_life_expectancy
GROUP BY country, year, CONCAT(country, year)
HAVING COUNT(CONCAT(country, year)) >1;

#Writing up script to id the duplicates for removeal
SELECT *
FROM (SELECT row_id, 
CONCAT(country, year),
ROW_NUMBER() OVER(PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year))as row_num
FROM world_life_expectancy) AS row_table
WHERE row_num >1;

#Removing the duplicates
DELETE FROM world_life_expectancy
WHERE row_id IN (
	SELECT row_id
	FROM (SELECT row_id, 
		CONCAT(country, year),
		ROW_NUMBER() OVER(PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year))as row_num
		FROM world_life_expectancy) AS row_table
	WHERE row_num >1);
    
    
#Find all blank and NULL status fields
SELECT *
FROM world_life_expectancy
WHERE status = ''
OR status IS NULL;

#ID the different values in the status field of the table
SELECT DISTINCT(status)
FROM world_life_expectancy
WHERE status <> '';

#ID developing countries
SELECT DISTINCT(country)
FROM world_life_expectancy
WHERE status = 'Developing';

#ID developed countries
SELECT DISTINCT(country)
FROM world_life_expectancy
WHERE status = 'Developed';

#Script will not work for update, cannot use subquery in update.
UPDATE world_life_expectancy
SET status = 'Developing'
WHERE country IN (SELECT DISTINCT(country)
	FROM world_life_expectancy
	WHERE status = 'Developing');

#script updates the t1 table if value is blank or developing in the t2 table after self JOIN
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
ON t1.country = t2.country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developing';

#script updates the t1 table if value is blank or developed in the t2 table after self JOIN
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
ON t1.country = t2.country
SET t1.status = 'Developed'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developed';


#Find all blank and NULL Life Expectancy fields
SELECT *
FROM world_life_expectancy
WHERE `Life expectancy` = ''
OR `Life expectancy` IS NULL;

SELECT country, year, `Life expectancy`
FROM world_life_expectancy;

#Using multi self joins to tie the table to itself twice then using t2 and t3 to find the avg life expectancy for the empty fields.
SELECT t1.country, t1.year, t1.`Life expectancy`,
	t2.country, t2.year, t2.`Life expectancy`,
	t3.country, t3.year, t3.`Life expectancy`,
	ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2, 1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
	AND t1.year = t2.year -1
JOIN world_life_expectancy t3
	ON t1.country = t3.country
	AND t1.year = t3.year +1
WHERE t1.`Life expectancy` = ''
OR t1.`Life expectancy` IS NULL;

#Update statment to apply the above
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
	AND t1.year = t2.year -1
JOIN world_life_expectancy t3
	ON t1.country = t3.country
	AND t1.year = t3.year +1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2, 1)
WHERE t1.`Life expectancy` = ''
OR t1.`Life expectancy` IS NULL;