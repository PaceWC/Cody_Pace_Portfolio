#Full Project #1 - World Life Expectancy Data (Exploratory Data Analysis)

#View all files in the table
SELECT * FROM world_life_expectancy.world_life_expectancy;

#View progress of life expectancy by country
SELECT country, MIN(`Life expectancy`), MAX(`Life expectancy`)
FROM world_life_expectancy.world_life_expectancy
GROUP BY country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <>0
ORDER BY country DESC;

#Country life expectancy growth over the last 15 years
SELECT country,
MIN(`Life expectancy`),
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) AS Life_Increase_Over_15_Years
FROM world_life_expectancy.world_life_expectancy
GROUP BY country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <>0
ORDER BY Life_Increase_Over_15_Years DESC;

#Global Avg life expectancy per year
SELECT year, ROUND(AVG(`Life expectancy`), 2)
FROM world_life_expectancy.world_life_expectancy
WHERE `Life expectancy` <> 0
AND `Life expectancy` <>0
GROUP BY year
ORDER BY year;

#AVG life and GDP by country
SELECT country,
	ROUND(AVG(`Life expectancy`), 1) AS Life_Exp,
	ROUND(AVG(gdp), 1) AS GDP
FROM world_life_expectancy
GROUP BY country
HAVING Life_Exp > 0
AND GDP > 0
ORDER BY GDP DESC;

#Provides average Life Expectancy grouped by low (<1500) and high GDP (1500+)
SELECT 
SUM(CASE WHEN gdp >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
ROUND(AVG(CASE WHEN gdp >= 1500 THEN `Life expectancy` ELSE NULL END)) High_GDP_Life_Expectancy,
SUM(CASE WHEN gdp <= 1500 THEN 1 ELSE 0 END) Low_GDP_Count,
ROUND(AVG(CASE WHEN gdp <= 1500 THEN `Life expectancy` ELSE NULL END)) Low_GDP_Life_Expectancy
FROM world_life_expectancy;

SELECT status, ROUND(AVG(`Life expectancy`), 1)
FROM world_life_expectancy
GROUP BY status;

#Life expectancy by country status
SELECT status, COUNT(DISTINCT country), ROUND(AVG(`Life expectancy`), 1)
FROM world_life_expectancy
GROUP BY status;

#BMI
SELECT country,
	ROUND(AVG(`Life expectancy`), 1) AS Life_Exp,
	ROUND(AVG(bmi), 1) AS bmi
FROM world_life_expectancy
GROUP BY country
HAVING Life_Exp > 0
AND bmi > 0
ORDER BY bmi DESC;

#Rolling total adult mortality
SELECT country,
year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY country ORDER BY year) AS Rolling_Total
FROM world_life_expectancy
WHERE country like '%United%';
