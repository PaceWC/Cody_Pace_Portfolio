--create the D597 Task 1 database.
CREATE DATABASE "D597 Task 1"
WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION_LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE "D597 Task 1" 
IS 'WGU D597 Task1 Scenario 2';

--create region table.
CREATE TABLE region (
    region_id SERIAL PRIMARY KEY,
    region_name TEXT
);
--create country table.
CREATE TABLE country (
    country_id SERIAL PRIMARY KEY,
    country_name TEXT,
    region_id_fk INTEGER,
	region_name TEXT
);
-- create item_type table.
CREATE TABLE item_type (
    item_type_id SERIAL PRIMARY KEY,
    item_type_name VARCHAR(30)
);
--create sales_channel table.
CREATE TABLE sales_channel (
    sales_channel_id SERIAL PRIMARY KEY,
    sales_channel_name VARCHAR(10)
);
 
--create initial sales_history table. includes all cols for data import. Will be normalized later.
CREATE TABLE sales_history (
region_name TEXT,
country_name TEXT,
item_type_name VARCHAR(30),
sales_channel_name VARCHAR(10),
order_priority CHAR(1),
order_date DATE,
order_id INTEGER PRIMARY KEY,
ship_date DATE,
units_sold INTEGER,
unit_price NUMERIC(12,2),
unit_cost NUMERIC(12,2),
total_revenue NUMERIC(12,2),
total_cost NUMERIC(12,2),
total_profit NUMERIC(12,2));

--import EcoMart data to sales_history table.
copy public.sales_history (
	region_name,
	country_name,
	item_type_name,
	sales_channel_name,
	order_priority,
	order_date,
	order_id,
	ship_date,
	units_sold,
	unit_price,
	unit_cost,
	total_revenue,
	total_cost,
	total_profit)
FROM 'C:/Users/PaceW/Desktop/WGU/Courses/D597-D~1/SCENAR~2/SCENAR~1/100000~1.CSV' 
DELIMITER ',' 
CSV HEADER 
ESCAPE '''';

--script to copy data from the sales_history table to the region table.
DELETE FROM region;
INSERT INTO region (region_name)
SELECT DISTINCT region_name
FROM sales_history;

--script to copy data from the sales_history table to the country table.
DELETE FROM country;
INSERT INTO country(country_name, region_name)
SELECT DISTINCT country_name, region_name
FROM sales_history;

--script to copy data from the sales_history table to the item_type table.
DELETE FROM item_type;
INSERT INTO item_type(item_type_name)
SELECT DISTINCT item_type_name
FROM sales_history;

--script to copy data from the sales_history table to the sales_channel table.
DELETE FROM sales_channel;
INSERT INTO sales_channel(sales_channel_name)
SELECT DISTINCT sales_channel_name
FROM sales_hsitory;

--add new columns to the sales_history table to support 3NF.
ALTER TABLE sales_history
	ADD country_id_fk INT,
	ADD sales_channel_id_fk INT,
	ADD item_type_id_fk INT;
	
--update country table with region_id_fk.
UPDATE country c
SET region_id_fk = r.region_id
FROM region r
WHERE c.region_name = r.region_name;

--update sales_history with country_id_fk.
UPDATE sales_history sh
SET country_id_fk = c.country_id
FROM country c
WHERE sh.country_name = c.country_name;

--update sales_history with sales_channel_id_fk.
UPDATE sales_history sh
SET sales_channel_id_fk = sc.sales_channel_id
FROM sales_channel sc
WHERE sh.sales_channel_name = sc.sales_channel_name;

--update sales_history with item_type_id_fk.
UPDATE sales_history sh
SET item_type_id_fk = it.item_type_id
FROM item_type it
WHERE sh.item_type_name = it.item_type_name;

--drop redundant name columns from sales_history.
ALTER TABLE sales_history
	DROP COLUMN country_name,
	DROP COLUMN region_name,
	DROP COLUMN sales_channel_name,
	DROP COLUMN item_type_name;

--drop redundate name column from country.
AFTER TABLE country
	DROP COLUMN region_name;
	
--add foreign key from country to region.
ALTER TABLE country
ADD CONSTRAINT fk_region FOREIGN KEY (region_id_fk) REFERENCES region(region_id);

--add foreign keys to sales_history.
ALTER TABLE sales_history
ADD CONSTRAINT fk_country FOREIGN KEY (country_id_fk) REFERENCES country(country_id),
ADD CONSTRAINT fk_item_type FOREIGN KEY (item_type_id_fk) REFERENCES item_type(item_type_id),
ADD CONSTRAINT fk_sales_channel FOREIGN KEY (sales_channel_id_fk) REFERENCES sales_channel(sales_channel_id);

--three queries for business problems.
--Q1: regional profitability.
SELECT r.region_name AS region,
    TO_CHAR(SUM(sh.total_profit), 'FM999,999,999,999.00') AS total_region_profit,
    TO_CHAR(SUM(sh.units_sold), 'FM999,999,999') AS units_sold,
    TO_CHAR(100.0 * SUM(sh.total_profit) / SUM(SUM(sh.total_profit)) OVER (),'FM999.00') || '%' AS percent_of_total
FROM sales_history sh
JOIN country c ON sh.country_id_fk = c.country_id
JOIN region r ON c.region_id_fk = r.region_id
GROUP BY r.region_name
ORDER BY SUM(sh.total_profit) DESC;

--Q2: item type sales performance.
SELECT it.item_type_name,
    TO_CHAR(SUM(sh.units_sold), 'FM999,999,999') AS units_sold,
    TO_CHAR(SUM(sh.total_profit), 'FM999,999,999,999.00') AS total_profit_item_type,
    TO_CHAR(100.0 * SUM(sh.total_profit) / SUM(SUM(sh.total_profit)) OVER (),'FM999.00') || '%' AS percent_of_total_profit
FROM sales_history sh
JOIN item_type it ON sh.item_type_id_fk = it.item_type_id
GROUP BY it.item_type_name
ORDER BY SUM(sh.total_profit) DESC, SUM(sh.units_sold) DESC;

--Q3: fullfillment performance.
SELECT it.item_type_name,
    ROUND(AVG(sh.ship_date - sh.order_date), 2) AS avg_days_to_ship
FROM sales_history sh
JOIN item_type it ON sh.item_type_id_fk = it.item_type_id
GROUP BY it.item_type_name
ORDER BY avg_days_to_ship DESC;

--optomization scripts to create indexes.
--improves JOIN performance with the Item_Type table.
CREATE INDEX idx_item_type_id_fk ON Sales_History(Item_Type_ID_FK);

--improves JOIN performance with the Sales_Channel table.
CREATE INDEX idx_sales_channel_id_fk ON Sales_History(Sales_Channel_ID_FK);

--speeds up queries that filter or sort by Order_Date (e.g., for trend analysis or fulfillment lag).
CREATE INDEX idx_order_date ON Sales_History(Order_Date);

--index on Ship_Date if you often analyze shipping timelines.
CREATE INDEX idx_ship_date ON Sales_History(Ship_Date);

--scripts to test index optomization.
--test if index on item_type_id_fk helps.
SELECT it.item_type_name, SUM(sh.units_sold)
FROM sales_history sh
JOIN item_type it ON sh.item_type_id_fk = it.item_type_id
GROUP BY it.item_type_name;

--test 2 if index on index on sales_channel_id_fk helps.
SELECT sc.sales_channel_name, SUM(sh.units_sold)
FROM sales_history sh
JOIN sales_channel sc ON sh.sales_channel_id_fk = sc.sales_channel_id
GROUP BY sc.sales_channel_name;

--test 3 if index on index on order_date helps.
SELECT * 
FROM sales_history 
WHERE order_date BETWEEN '2015-01-01' AND '2016-12-31';

--test 4 if index on index on ship_date helps.
SELECT AVG(ship_date - order_date) AS avg_days_to_ship
FROM sales_history;