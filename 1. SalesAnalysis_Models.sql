/*
This SQL project explores the sales data of a toy model business.
It demonstrates the following skills:
	1. Subqueries
	2. Aggregate Functions
	3. Window Functions
	4. CTEs
	5. XML PATH Function
	6. Temporary Table

Some questions this project answers include:
	1. Which Product Line generated the most revenue on the overall dataset?
	2. What are the revenue for each year?
	3. What are the revenue for each Dealsize?
	4. What are the top 3 performing months of each year?
	5. What Product Line sold best in the best performing month of each year?
	6. Which customers are most loyal? (Using RFM Analysis)
	7. Which two product codes are bought together in the same order?
	8. What city has the highest number of sales in a specific country?


The sales data (a csv file) is downloaded from the following url:
https://www.kaggle.com/datasets/kumarraviranjan/sales-data

The downloaded csv file is then imported to a database (Microsoft SQL Server).
*/

--Inspecting data
SELECT *
FROM [dbo].[sales_data_sample 2]; -- 2823 records

--Checking unique values
SELECT DISTINCT ORDERNUMBER
FROM [dbo].[sales_data_sample 2]; -- 307 distinct ordernumbers

SELECT DISTINCT CUSTOMERNAME
FROM [dbo].[sales_data_sample 2]; --  92 distinct customernames

SELECT DISTINCT STATUS
FROM [dbo].[sales_data_sample 2]; -- 6 distinct status

SELECT DISTINCT YEAR_ID
FROM [dbo].[sales_data_sample 2]; -- 3 distinct years

SELECT DISTINCT PRODUCTLINE
FROM [dbo].[sales_data_sample 2]; -- 7 distinct productlines

SELECT DISTINCT COUNTRY
FROM [dbo].[sales_data_sample 2]; -- 19 distinct countries

SELECT DISTINCT DEALSIZE
FROM [dbo].[sales_data_sample 2]; -- 3 distinct dealsizes

SELECT DISTINCT TERRITORY
FROM [dbo].[sales_data_sample 2]; -- 4 distinct territories


--ANALYSIS
--Grouping SALES by PRODUCTLINE
SELECT PRODUCTLINE, ROUND(SUM(SALES), 2) AS Revenue
FROM [dbo].[sales_data_sample 2]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;
--Classic Cars generated the most revenue.

--Grouping SALES by YEAR_ID
SELECT YEAR_ID, ROUND(SUM(SALES), 2) AS Revenue
FROM [dbo].[sales_data_sample 2]
GROUP BY YEAR_ID
ORDER BY 2 DESC;
--2005 has the least revenue; let's further investigate if the data spans all 12 months in the year 2005
--Checking unique month values in 2005
SELECT DISTINCT MONTH_ID
FROM [dbo].[sales_data_sample 2]
WHERE YEAR_ID = 2005;
--Results indicate that the dataset only contains 5 months in the year 2005

--Grouping SALES by DEALSIZE
SELECT DEALSIZE, ROUND(SUM(SALES), 2) AS Revenue
FROM [dbo].[sales_data_sample 2]
GROUP BY DEALSIZE
ORDER BY 2 DESC;


--Best performing months (in terms of revenue) by YEAR_ID
--2003
SELECT TOP 3 MONTH_ID, ROUND(SUM(SALES), 2) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample 2]
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC;

--2004
SELECT TOP 3 MONTH_ID, ROUND(SUM(SALES), 2) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample 2]
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC;

--In both 2003 and 2004, November generated the most revenue.

--2005 is INCOMPLETE; it only has sales data covering January to May
SELECT MONTH_ID, ROUND(SUM(SALES), 2) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample 2]
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID
ORDER BY 2 DESC;


--Further investigating the products sold in November of 2003 and 2004.
--2003
SELECT MONTH_ID, PRODUCTLINE, ROUND(SUM(SALES), 2) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample 2]
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

--2004
SELECT MONTH_ID, PRODUCTLINE, ROUND(SUM(SALES), 2) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample 2]
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

--Classic Cars ranked 1st and Vintage Cars ranked 2nd in both 2003's and 2004's November.


--RFM Analysis (Recency, Frequency, Monetary): Best customers
SELECT
	CUSTOMERNAME,
	ROUND(SUM(SALES), 2) AS MonetaryValue,
	ROUND(AVG(SALES), 2) AS AvgMonetaryValue,
	COUNT(ORDERNUMBER) AS Frequency,
	MAX(ORDERDATE) AS last_order_date,
	(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2]) AS max_order_date,
	DATEDIFF(dd, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2])) AS Recency
FROM [dbo].[sales_data_sample 2]
GROUP BY CUSTOMERNAME;

--Putting the above query result into a CTE called rfm
;WITH rfm AS (
	SELECT
		CUSTOMERNAME,
		ROUND(SUM(SALES), 2) AS MonetaryValue,
		ROUND(AVG(SALES), 2) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2]) AS max_order_date,
		DATEDIFF(dd, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2])) AS Recency
	FROM [dbo].[sales_data_sample 2]
	GROUP BY CUSTOMERNAME
)
SELECT r.*
FROM rfm AS r;

--Adding the window function 'NTILE()'
;WITH rfm AS (
	SELECT
		CUSTOMERNAME,
		ROUND(SUM(SALES), 2) AS MonetaryValue,
		ROUND(AVG(SALES), 2) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2]) AS max_order_date,
		DATEDIFF(dd, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2])) AS Recency
	FROM [dbo].[sales_data_sample 2]
	GROUP BY CUSTOMERNAME
)
SELECT
	r.*,
	NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,      -- Bigger value -> more recent
	NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,       -- Bigger value -> higher frequency
	NTILE(4) OVER (ORDER BY AvgMonetaryValue) AS rfm_monetary  -- Bigger value -> more $
FROM rfm AS r;

--Passing the previous step's result into another CTE called rfm_calc
;WITH rfm AS (
	SELECT
		CUSTOMERNAME,
		ROUND(SUM(SALES), 2) AS MonetaryValue,
		ROUND(AVG(SALES), 2) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2]) AS max_order_date,
		DATEDIFF(dd, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2])) AS Recency
	FROM [dbo].[sales_data_sample 2]
	GROUP BY CUSTOMERNAME
),
rfm_calc AS (
	SELECT
		r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,      -- Bigger value -> more recent
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,       -- Bigger value -> higher frequency
		NTILE(4) OVER (ORDER BY AvgMonetaryValue) AS rfm_monetary  -- Bigger value -> more $
	FROM rfm AS r
)
SELECT
	c.*,
	rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary AS varchar) AS rfm_cell_string
FROM rfm_calc AS c;

--Making the above into a temp table
DROP TABLE IF EXISTS #rfm
;WITH rfm AS (
	SELECT
		CUSTOMERNAME,
		ROUND(SUM(SALES), 2) AS MonetaryValue,
		ROUND(AVG(SALES), 2) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2]) AS max_order_date,
		DATEDIFF(dd, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample 2])) AS Recency
	FROM [dbo].[sales_data_sample 2]
	GROUP BY CUSTOMERNAME
),
rfm_calc AS (
	SELECT
		r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,      -- Bigger value -> more recent
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,       -- Bigger value -> higher frequency
		NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary     -- Bigger value -> more $
	FROM rfm AS r
)
SELECT
	c.*,
	rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary AS varchar) AS rfm_cell_string
INTO #rfm
FROM rfm_calc AS c;

--Exploring the temp table #rfm
SELECT *
FROM #rfm;

/*
SELECT DISTINCT rfm_cell_string, rfm_recency, rfm_frequency, rfm_monetary
FROM #rfm;
*/

SELECT rfm_cell_string, rfm_recency, rfm_frequency, rfm_monetary, COUNT(rfm_cell_string) AS rfm_count
FROM #rfm
GROUP BY rfm_cell_string, rfm_recency, rfm_frequency, rfm_monetary;

--Segmenting customers on the temp table using CASE statements
SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		WHEN rfm_cell_string IN (111, 112, 121, 122, 123, 132, 211, 212, 221) THEN 'lost customers'
		WHEN rfm_cell_string IN (133, 144, 234, 244, 343, 344) THEN 'slipping away, cannot lose' -- Big spenders who haven’t purchased lately
		WHEN rfm_cell_string IN (311, 412) THEN 'new customers'
		WHEN rfm_cell_string IN (222, 223, 232, 233, 322, 421, 422, 423) THEN 'potential churners'
		WHEN rfm_cell_string IN (332, 333) THEN 'active' -- Customers who buy recently and frequently, but at low price points
		WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
	END AS rfm_segment
FROM #rfm;

/* Testing to see if there are any null values
SELECT *
FROM (
	SELECT rfm_recency, rfm_frequency, rfm_monetary, rfm_cell_string,
		CASE
			WHEN rfm_cell_string IN (111, 112, 121, 122, 123, 132, 211, 212, 221) THEN 'lost customers'
			WHEN rfm_cell_string IN (133, 144, 234, 244, 343, 344) THEN 'slipping away, cannot lose' -- Big spenders who haven’t purchased lately
			WHEN rfm_cell_string IN (311, 412) THEN 'new customers'
			WHEN rfm_cell_string IN (222, 223, 232, 233, 322, 421, 422, 423) THEN 'potential churners'
			WHEN rfm_cell_string IN (332, 333) THEN 'active' -- Customers who buy recently and frequently, but at low price points
			WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
		END AS rfm_segment,
		COUNT(rfm_cell_string) AS rfm_count
	FROM #rfm
	GROUP BY rfm_recency, rfm_frequency, rfm_monetary, rfm_cell_string
	) AS x
WHERE rfm_segment IS NULL;
*/


-- What products are most often sold together?
-- Narrowing down to just the shipped orders
SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
FROM [dbo].[sales_data_sample 2]
WHERE STATUS = 'Shipped'
GROUP BY ORDERNUMBER;

-- Exploring some of the ORDERNUMBER_s
SELECT * FROM [dbo].[sales_data_sample 2] WHERE ORDERNUMBER = 10411;
SELECT * FROM [dbo].[sales_data_sample 2] WHERE ORDERNUMBER = 10125;

-- Which ORDERNUMBER_s have prod_code_count = 2?
SELECT ORDERNUMBER
FROM (
	SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
	FROM [dbo].[sales_data_sample 2]
	WHERE STATUS = 'Shipped'
	GROUP BY ORDERNUMBER
	) AS shipped_ord
WHERE prod_code_count = 2;

-- Using the above result (ORDERNUMBER_s that have two product codes) as a filter to select the PRODUCTCODE_s.
SELECT PRODUCTCODE
FROM [dbo].[sales_data_sample 2]
WHERE ORDERNUMBER IN
	(
	SELECT ORDERNUMBER
	FROM (
		SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
		FROM [dbo].[sales_data_sample 2]
		WHERE STATUS = 'Shipped'
		GROUP BY ORDERNUMBER
		) AS shipped_ord
	WHERE prod_code_count = 2
	);

-- Checking whether the ORDERNUMBER column is listed in order -> Ans: Not in order
SELECT ORDERNUMBER, PRODUCTCODE FROM [dbo].[sales_data_sample 2]
-- ORDER BY ORDERNUMBER
SELECT ORDERNUMBER, PRODUCTCODE FROM [dbo].[sales_data_sample 2] ORDER BY ORDERNUMBER


-- Ordering by ORDERNUMBER_s
SELECT PRODUCTCODE--, ORDERNUMBER
FROM [dbo].[sales_data_sample 2]
WHERE ORDERNUMBER IN
	(
	SELECT ORDERNUMBER
	FROM (
		SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
		FROM [dbo].[sales_data_sample 2]
		WHERE STATUS = 'Shipped'
		GROUP BY ORDERNUMBER
		) AS shipped_ord
	WHERE prod_code_count = 2
	)
ORDER BY ORDERNUMBER;

-- Appending the ',' separator to the front of each row; then roll up all the rows to just one row by converting the result to XML.
SELECT ',' + PRODUCTCODE
FROM [dbo].[sales_data_sample 2]
WHERE ORDERNUMBER IN
	(
	SELECT ORDERNUMBER
	FROM (
		SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
		FROM [dbo].[sales_data_sample 2]
		WHERE STATUS = 'Shipped'
		GROUP BY ORDERNUMBER
		) AS shipped_ord
	WHERE prod_code_count = 2
	)
ORDER BY ORDERNUMBER
FOR XML PATH ('');

-- Removing the first comma by putting the above result inside the STUFF function.
-- The outermost SELECT does not have a FROM clause.
SELECT p_code = STUFF(
	(
		SELECT ',' + PRODUCTCODE
		FROM [dbo].[sales_data_sample 2]
		WHERE ORDERNUMBER IN
			(
			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
				FROM [dbo].[sales_data_sample 2]
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
				) AS shipped_ord
			WHERE prod_code_count = 2
			)
		ORDER BY ORDERNUMBER
		FOR XML PATH ('')
	)
	, 1, 1, '');



-- Finalizing:
-- Outermost query
	-- Adding the FROM clause
	-- Adding the sales1.ORDERNUMBER column to SELECT
	-- Adding the WHERE clause to reduce row count to 38;
		-- it contains a subquery which is identical to the (now commented out) first condition in the WHERE clause of the subquery of the outermost SELECT
	-- Adding the DISTINCT keyword to reduce row count to 19 (duplicates are removed)
	-- Adding ORDER BY p_code (i.e.: ORDER BY 2); we'll be able to see which ORDERNUMBER_s have identical PRODUCTCODE_s
-- Second outermost query: turn it into a correlated subquery
	-- Giving the alias sales2 to the table in the second outermost FROM
	-- Adding another condition to the second outermost WHERE
		-- This new condition ensures that only the PRODUCTCODE_s whose ORDERNUMBER_s match sales1.ORDERNUMBER_s of the outermost SELECT are chosen.
		-- note that both the commented-out and the new conditions filter rows based on ORDERNUMBER_s
SELECT DISTINCT
	sales1.ORDERNUMBER,
	p_code = STUFF(
		(
			SELECT ',' + PRODUCTCODE
			FROM [dbo].[sales_data_sample 2]  AS sales2
			WHERE
				/*ORDERNUMBER IN
					(
					SELECT ORDERNUMBER
					FROM (
						SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
						FROM [dbo].[sales_data_sample 2]
						WHERE STATUS = 'Shipped'
						GROUP BY ORDERNUMBER
						) AS shipped_ord
					WHERE prod_code_count = 2
					)
				AND*/
				sales2.ORDERNUMBER = sales1.ORDERNUMBER
			--ORDER BY ORDERNUMBER  --This line becomes unnecessary, because later the DISTINCT in the outermost query will reduce 38 rows to 19 rows.
			FOR XML PATH ('')
		)
		, 1, 1, '')
FROM [dbo].[sales_data_sample 2] AS sales1
WHERE
	ORDERNUMBER IN
		(
		SELECT ORDERNUMBER
		FROM (
			SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
			FROM [dbo].[sales_data_sample 2]
			WHERE STATUS = 'Shipped'
			GROUP BY ORDERNUMBER
			) AS shipped_ord
		WHERE prod_code_count = 2
		)
ORDER BY 2;


-- Simplifying the sql code by clearing out commented parts, the result is as follows:
SELECT DISTINCT
	sales1.ORDERNUMBER,
	p_code = STUFF(
		(
			SELECT ',' + PRODUCTCODE
			FROM [dbo].[sales_data_sample 2]  AS sales2
			WHERE sales2.ORDERNUMBER = sales1.ORDERNUMBER
			FOR XML PATH ('')
		)
		, 1, 1, '')
FROM [dbo].[sales_data_sample 2] AS sales1
WHERE
	ORDERNUMBER IN
		(
		SELECT ORDERNUMBER
		FROM (
			SELECT ORDERNUMBER, COUNT(*) AS prod_code_count
			FROM [dbo].[sales_data_sample 2]
			WHERE STATUS = 'Shipped'
			GROUP BY ORDERNUMBER
			) AS shipped_ord
		WHERE prod_code_count = 2
		)
ORDER BY 2;


-- What city has the highest number of sales in a specific country?
SELECT TOP 1 t2.COUNTRY, t2.CITY, SUM(t2.SALES) AS sum_city_sales
FROM [dbo].[sales_data_sample 2] AS t2
WHERE t2.COUNTRY = 'Australia'
GROUP BY t2.COUNTRY, t2.CITY
ORDER BY 3 DESC

-- List all the countries with their respective city that generated the highest revenue.
-- Breaking down the problem by re-using the above result (t2 is modified to t3) in the subquery, and just selecting the CITY column in the outer query:
SELECT CITY
FROM (
	SELECT TOP 1 t3.COUNTRY, t3.CITY, SUM(t3.SALES) AS sum_city_sales
	FROM [dbo].[sales_data_sample 2] AS t3
	WHERE t3.COUNTRY = 'Australia'
	GROUP BY t3.COUNTRY, t3.CITY
	ORDER BY 3 DESC
) AS t2

-- Same thing goes for selecting the sum_city_sales column:
SELECT sum_city_sales
FROM (
	SELECT TOP 1 t3.COUNTRY, t3.CITY, SUM(t3.SALES) AS sum_city_sales
	FROM [dbo].[sales_data_sample 2] AS t3
	WHERE t3.COUNTRY = 'Australia'
	GROUP BY t3.COUNTRY, t3.CITY
	ORDER BY 3 DESC
) AS t2

/* Putting the results from the prior two steps into the outer most SELECT, and giving them aliases (city_name, city_sum), 
   and modifying these two subqueries' WHERE clauses to become correlated subqueries */
SELECT DISTINCT
	t1.COUNTRY,
	city_name = (
			SELECT CITY
			FROM (
				SELECT TOP 1 t3.COUNTRY, t3.CITY, SUM(t3.SALES) AS sum_city_sales
				FROM [dbo].[sales_data_sample 2] AS t3
				WHERE t3.COUNTRY = t1.COUNTRY
				GROUP BY t3.COUNTRY, t3.CITY
				ORDER BY 3 DESC
			) AS t2
		),
	city_sum = (
			SELECT sum_city_sales
			FROM (
				SELECT TOP 1 t3.COUNTRY, t3.CITY, SUM(t3.SALES) AS sum_city_sales
				FROM [dbo].[sales_data_sample 2] AS t3
				WHERE t3.COUNTRY = t1.COUNTRY
				GROUP BY t3.COUNTRY, t3.CITY
				ORDER BY 3 DESC
			) AS t2
		)
FROM [dbo].[sales_data_sample 2] AS t1
ORDER BY 1;


-- Alternative
;WITH top_city_sales AS (
	SELECT
		COUNTRY,
		CITY,
		SUM(SALES) AS sum_city_sales
	FROM [dbo].[sales_data_sample 2]
	GROUP BY COUNTRY, CITY
)
SELECT tcs_L.*--, tcs_R.*
FROM top_city_sales AS tcs_L
	LEFT JOIN top_city_sales AS tcs_R
	ON
	tcs_L.COUNTRY = tcs_R.COUNTRY
		AND
	tcs_L.sum_city_sales < tcs_R.sum_city_sales
WHERE tcs_R.sum_city_sales IS NULL
;



-- What is the best product (PRODUCTCODE) in the United States?
-- Exploring the dataset specifically in 'USA'
SELECT *
FROM [dbo].[sales_data_sample 2]
WHERE COUNTRY = 'USA';

-- Solution
SELECT
	PRODUCTLINE,
	PRODUCTCODE,
	SUM(SALES) AS prod_sales,
	COUNT(SALES) AS prod_count
FROM [dbo].[sales_data_sample 2]
WHERE COUNTRY = 'USA'
GROUP BY PRODUCTLINE, PRODUCTCODE
ORDER BY 3 DESC;

-- What is the best product (PRODUCTLINE) in the United States?
SELECT
	PRODUCTLINE,
	SUM(SALES) AS prod_sales,
	COUNT(SALES) AS prod_count
FROM [dbo].[sales_data_sample 2]
WHERE COUNTRY = 'USA'
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;
