-- Apple Retails Millions Rows Sales Schemas


-- DROP TABLE command
DROP TABLE IF EXISTS warranty;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS stores;

-- CREATE TABLE commands

CREATE TABLE stores(
store_id VARCHAR(5) PRIMARY KEY,
store_name	VARCHAR(30),
city	VARCHAR(25),
country VARCHAR(25)
);

DROP TABLE IF EXISTS category;
CREATE TABLE category
(category_id VARCHAR(10) PRIMARY KEY,
category_name VARCHAR(20)
);

CREATE TABLE products
(
product_id	VARCHAR(10) PRIMARY KEY,
product_name	VARCHAR(50),
category_id	VARCHAR(10),
launch_date	date,
price FLOAT,
CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);


DELETE FROM sales;
SELECT * FROM sales
 SELECT * FROM sales
 WHERE store_id='103';


CREATE TABLE sales
(
sale_id	VARCHAR(15) PRIMARY KEY,
sale_date	DATE,
store_id	VARCHAR(10), -- this fk
product_id	VARCHAR(10), -- this fk
quantity INT,
CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);


CREATE TABLE warranty
(
claim_id VARCHAR(10) PRIMARY KEY,
sale_id	VARCHAR(15),
claim_date DATE,
repair_status VARCHAR(15),
CONSTRAINT fk_orders FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);


SELECT* FROM category;
SELECT* FROM products;
SELECT* FROM sales;
SELECT* FROM stores;
SELECT* FROM warranty;

-- EDA
SELECT DISTINCT repair_status FROM warranty;
SELECT COUNT(*) FROM sales;-- 1 million sales


-- apple sales analaysisi of 1 million row data 
SELECT* FROM category;
SELECT* FROM products;
SELECT* FROM sales;
SELECT* FROM stores;
SELECT* FROM warranty;

-- EDA
SELECT DISTINCT repair_status FROM warranty;
SELECT COUNT(*) FROM sales;-- 1 million sales

--et 222.0713 ms
--pt 0.089 ms
-- after index 17.707
EXPLAIN ANALYSE
SELECT* FROM sales
WHERE product_id ='107'

CREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);


--et 110.136 ms
--pt 0.070 ms
--after index  et 5.682 ms

EXPLAIN ANALYSE
SELECT* FROM sales
WHERE store_id ='31'

CREATE INDEX sales_store_id ON sales(store_id);

-- Business Problems
-- Medium level  Problems

-- 1. Find the number of stores in each country.

		SELECT country,
		       COUNT(store_name) AS no_store
			 FROM stores
			 GROUP BY country
			 ORDER BY no_store DESC;-- from most of 
			 
-- Q.2 Calculate the total number of units sold by each store.	

  SELECT st.store_name,
  		 s.store_id,
  		SUM(s.quantity) AS total_no_units_sold
  FROM stores AS st
  JOIN
  sales AS s
  ON st.store_id = s.store_id
  GROUP BY st.store_name,s.store_id
   ORDER BY total_no_units_sold DESC;

-- Q.3 Identify how many sales occurred in December 2023.

	SELECT 
	COUNT(sale_id) as total_sale 
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023'

SELECT * FROM sales

-- Q.4 Determine how many stores have never had a warranty claim filed.

 SELECT COUNT(*) FROM stores
 WHERE store_id NOT IN (
		 SELECT DISTINCT store_id 
 		FROM sales AS s
		 RIGHT JOIN warranty AS w
 		ON s.sale_id = w.sale_id
		 );
SELECT 
  COUNT(*) AS total_stores
FROM
  stores
WHERE
  store_id NOT IN (SELECT DISTINCT
          store_id
      FROM
          sales AS s
              RIGHT JOIN
          warranty AS w ON w.sale_id = s.sale_id)


-- Q5 Calculate the percentage of warranty claims marked as "REPLACED".

no of claims in Replacaed/total * 100

	SELECT 
			ROUND(COUNT(claim_id)
									/(SELECT COUNT(*)FROM warranty ) :: NUMERIC
			* 100,2) AS Avg_Of_Replaced_claim
	FROM warranty
	WHERE repair_status ='Replaced';


--Q6 Identify which store had the highest total units sold in the last year.

	SELECT st.store_id,
			st.store_name,
			SUM(quantity) AS total_quantity_sold
	FROM sales AS s
	JOIN 
	stores AS st
	ON s.store_id = st.store_id
	WHERE sale_date>= (CURRENT_DATE - INTERVAL '1 YEAR')
	GROUP BY st.store_id,st.store_name
	ORDER BY total_quantity_sold DESC LIMIT 1;
	

-- Q7 Count the number of unique products sold in the last year.

--my 1 
	SELECT DISTINCT p.product_name ,
						COUNT(quantity) AS sold_product
	FROM products AS p
	JOIN 
	sales AS s
	ON p.product_id = s.product_id
	WHERE sale_date>= (CURRENT_DATE - INTERVAL '1 YEAR')
	GROUP BY p.product_name;
--2
 SELECT COUNT(DISTINCT(product_id))
 FROM sales
WHERE sale_date>= (CURRENT_DATE - INTERVAL '1 YEAR');

-- Q8 Find the average price of products in each category.

	SELECT DISTINCT(c.category_name),
					AVG(p.price) AS avg_price
	FROM products AS p
	JOIN category AS c
	ON c.category_id = p.category_id
	GROUP BY c.category_name;


--Q9 How many warranty claims were filed in 2020?

	SELECT COUNT(claim_date)
	FROM warranty
	WHERE TO_CHAR(claim_date, 'YYYY') ='2022';

--Q10 For each store, identify the best-selling day based on highest quantity sold.
	
	SELECT * FROM
	(
		SELECT  store_id ,
				sale_date AS Best_selling_day,
				SUM(quantity) AS highest_quantity_sold,
				RANK() OVER( PARTITION BY store_id ORDER BY SUM(quantity) DESC ) AS rank
		FROM sales
		GROUP BY sale_date,store_id
  ) AS t1
  WHERE RANK=1;
	


	WITH RankedSales AS (
    SELECT  
        store_id,
        sale_date AS best_selling_day,
        SUM(quantity) AS highest_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS row_num
    FROM sales
    GROUP BY store_id, sale_date
)
SELECT store_id, best_selling_day, highest_quantity_sold
FROM RankedSales
WHERE row_num = 1
ORDER BY store_id;

-- MEDIUM TO ADVANCE 
-- Q11 Identify the least selling product in each country for each year based on total units(quantity) sold

	WITH product_rank
	AS
	(
	SELECT  st.country,
				s.product_id,
				p.product_name,
			SUM(s.quantity) AS total_units_sold,
			RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) AS RANK
	FROM stores AS st
	JOIN sales AS s
	ON st.store_id = s.store_id
	JOIN products AS p
	ON p.product_id = s.product_id
	GROUP BY st.country,s.product_id,p.product_name
	)
	SELECT * FROM product_rank
	WHERE RANK = 1;


--Q12 calculate how many warranty claims were field within 180 days of a product sale 

	SELECT COUNT(w.claim_id)
	FROM sales AS s
	LEFT JOIN warranty AS w
	ON s.sale_id = w.sale_id
	WHERE sale_date - claim_date <= 180;


-- Q13 determine the how many warranty claims were fiels for product launched in the last to years
	
	SELECT p.product_name,
			COUNT(w.claim_id) AS NO_claims,
			COUNT(s.sale_id ) AS NO_SOLD
	FROM warranty AS w
	RIGHT JOIN sales AS s
	ON s.sale_id = w.sale_id
	JOIN products AS p
	ON p.product_id = s.product_id
	WHERE  
			p.launch_date >= CURRENT_DATE  - INTERVAL ' 2 years' 
	GROUP BY p.product_name
	HAVING COUNT(w.claim_id) > 0 ;

--Q14 List the months in the last three years where sales exceeded 500 units in the USA.

		SELECT 
				TO_CHAR(s.sale_date,'MM-YYYY') AS month,
				SUM(s.quantity)
		FROM sales AS  s
		JOIN stores AS st
		ON st.store_id = s.store_id
		WHERE st.country ='USA'
		AND s.sale_date >= CURRENT_DATE - INTERVAL '3 year'
		GROUP BY sale_date
		HAVING 	SUM(s.quantity) > 500;	


-- Q15 Identify the product category with the most warranty claims filed in the last two years.

	SELECT c.category_name,
			COUNT(w.claim_id)  AS total_claims
	FROM warranty AS w
	LEFT JOIN sales AS s
	ON s.sale_id = w.sale_id
	JOIN products AS p
	ON p.product_id = s.product_id
	JOIN category AS c
	ON c.category_id = p.category_id
		WHERE w.claim_date >= CURRENT_DATE - INTERVAL ' 2 year'
	GROUP BY c.category_name ;


-- Q 16 Determine the percentage chance of receiving warranty claims after each purchase for each country.

	SELECT country,
			toatal_sale,
			total_claim,
			COALESCE(toatal_sale :: NUMERIC /total_claim :: NUMERIC  * 100,0 ) AS risk
	FROM
	(
		SELECT st.country,
				SUM(quantity) AS toatal_sale,
				COUNT(w.claim_id) AS total_claim
		FROM warranty AS w
		LEFT JOIN sales AS s
		ON w.sale_id = s.sale_id
		JOIN stores AS st
		ON st.store_id = s.store_id
		GROUP BY st.country
    ) t2
	ORDER BY risk DESC;


--Q17 Analyze the year-by-year growth ratio for each store.
	
	WITH yearly_sales
	AS
	(
	SELECT  s.store_id,
			st.store_name,
			EXTRACT( YEAR FROM sale_date) AS year,
			SUM(s.quantity * p.price) AS total_sale
	FROM sales AS s
	JOIN 
	products AS p
	ON s.product_id = p.product_id
	JOIN stores AS st
	ON st.store_id = s.store_id
	GROUP BY s.store_id,EXTRACT( YEAR FROM sale_date),st.store_name
	ORDER BY st.store_name,year
	),
	growth_ratio
	AS
	(
	 SELECT 
			
			store_name,
			year,
			LAG(total_sale,1) OVER(PARTITION BY store_name ORDER BY year) AS last_year,
			total_sale  AS current_year
			
		FROM yearly_sales
		ORDER BY CAST(store_id AS INTEGER), year
		)
		SELECT 
				store_name,
			    year,
		        last_year,
				current_year,
				ROUND(
					(current_year - last_year) :: NUMERIC / last_year :: NUMERIC * 100 ,2
				 )
				AS GROWTH_RATIO
		FROM growth_ratio
		WHERE last_year IS NOT NULL
		AND 
		YEAR <> EXTRACT ( YEAR FROM CURRENT_DATE );


--Q18 Calculate the correlation between product price and warranty claims for products sold
--in the last five years, segmented by price range.

SELECT 
		CASE 
			WHEN p.price < 500 THEN 'less Expensive product'
			WHEN p.price BETWEEN 500 AND 1600 THEN ' Mid Range Product'
			ELSE 'Expensive Product' 
			END AS price_range,
      COUNT(w.claim_id) AS total_claim
FROM warranty AS w
LEFT JOIN sales AS s 
ON s.sale_id = w.sale_id
LEFT JOIN products AS p 
ON s.product_id = p.product_id 
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '5 years' 
GROUP BY price_range;


--Q19 Identify the store with the highest percentage of " Repaired" claims relative to total claims filed.

WITH total_repaired
AS 
   (SELECT st.store_name,
   			s.store_id,
   			COUNT(w.claim_id) AS total_repaired
   FROM warranty AS w
   LEFT JOIN sales AS s
   ON s.sale_id = w.sale_id
   JOIN stores As st 
   ON s.store_id = st.store_id
   WHERE repair_status = 'Repaired'
   GROUP BY st.store_name,s.store_id
   ),
  claims_repair
  AS
	(SELECT st.store_name,
			s.store_id,
   			COUNT(w.claim_id) AS total_claims_for_repaired
   FROM warranty AS w
   LEFT JOIN sales AS s
   ON s.sale_id = w.sale_id
   JOIN stores As st 
   ON s.store_id = st.store_id
   GROUP BY st.store_name,s.store_id
   )
   SELECT 
   			tr.store_name,
			 tr.store_id,
			tr.total_repaired,
			cr.total_claims_for_repaired,
			ROUND(tr.total_repaired :: NUMERIC / cr.total_claims_for_repaired :: NUMERIC * 100,2) AS ratio_repaired
	FROM total_repaired AS tr
	JOIN
  	claims_repair AS cr
	 ON tr.store_id = cr.store_id


--Q20 Write a query to calculate the monthly running total of sales for each store over the past four years 
--and compare trends during this period.
	
	WITH monthly_sales
	AS
	(
	 SELECT store_id,
			EXTRACT( YEAR FROM sale_date) AS year,
			EXTRACT(MONTH FROM sale_date) AS month,
			SUM(p.price * s.quantity) AS total_revenue
	FROM sales AS s
	JOIN products AS p
	ON p.product_id = s.product_id
	GROUP BY store_id,EXTRACT( YEAR FROM sale_date),month
	ORDER BY CAST(s.store_id AS INT),year, month ASC
	) 
	SELECT 
			store_id,
			year,
			month,
			total_revenue,
			SUM(total_revenue) OVER(PARTITION BY store_id ORDER BY year,month ) AS runnig_total
	FROM monthly_sales
	

	
--Q21 Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 
--6-12 months, 12-18 months, and beyond 18 months.

	SELECT p.launch_date,
			p.product_name,
			s.sale_date,
			s.quantity,
			CASE
				WHEN s.sale_date < p.launch_date  THEN ' prorder'
				WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN ' 0-6 months'
				WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 month' AND p.launch_date + INTERVAL '12 month'THEN ' 6-12 months'
				WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 month' AND p.launch_date + INTERVAL '18 month'THEN ' 6-12 months'
			    ELSE ' 18 months +'
			END AS sales_trend
	FROM sales AS s
	JOIN products AS p
	ON s.product_id = p.product_id
	GROUP BY p.launch_date,p.product_name,s.sale_date,s.quantity;


-- Q22 - Identify the top 3 best-selling products for each country in the last two years.

	WITH product_sales AS (
    SELECT 
        st.country,
        p.product_id,
        p.product_name,
        SUM(s.quantity) AS total_units_sold,
        RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity) DESC) AS rank
    FROM sales AS s
    JOIN stores AS st
	ON st.store_id = s.store_id
    JOIN products AS p 
	ON p.product_id = s.product_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY st.country, p.product_id, p.product_name
)
SELECT * 
FROM product_sales
WHERE rank <= 3;

--Q23 - Find stores where sales have dropped for 3 consecutive months.				

WITH sales_trend AS (
    SELECT 
        s.store_id,
        st.store_name,
        TO_CHAR(s.sale_date, 'YYYY-MM') AS sale_month,
        SUM(s.quantity) AS total_units_sold,
        LAG(SUM(s.quantity), 1) OVER(PARTITION BY s.store_id ORDER BY TO_CHAR(s.sale_date, 'YYYY-MM')) AS last_month,
        LAG(SUM(s.quantity), 2) OVER(PARTITION BY s.store_id ORDER BY TO_CHAR(s.sale_date, 'YYYY-MM')) AS two_months_ago
    FROM sales AS s
    JOIN stores AS st 
	ON st.store_id = s.store_id
    GROUP BY s.store_id, st.store_name, TO_CHAR(s.sale_date, 'YYYY-MM')
)
SELECT store_id, store_name, sale_month, total_units_sold
FROM sales_trend
WHERE total_units_sold < last_month AND last_month < two_months_ago;

-- Q24 - Calculate the average time between a product sale and a warranty claim.

	SELECT 
    p.product_name,
    ROUND(AVG(w.claim_date - s.sale_date), 2) AS avg_days_to_claim
FROM warranty AS w
JOIN sales AS s
ON s.sale_id = w.sale_id
JOIN products AS p
ON s.product_id = p.product_id
WHERE w.claim_date IS NOT NULL
GROUP BY p.product_name
ORDER BY avg_days_to_claim DESC;

--Q25 - Identify stores with unusually low warranty claims compared to total sales.

 WITH store_sales AS (
    SELECT 
        s.store_id,
        COUNT(s.sale_id) AS total_sales
    FROM sales s
    GROUP BY s.store_id
),
store_claims AS (
    SELECT 
        s.store_id,
        COUNT(w.claim_id) AS total_claims
    FROM warranty w
    JOIN sales s 
	ON w.sale_id = s.sale_id  
    GROUP BY s.store_id
	ORDER BY CAST(s.store_id AS INT) 
)
SELECT 
    ss.store_id,
    ss.total_sales,
    COALESCE(sc.total_claims, 0) AS total_claims,
    ROUND((COALESCE(sc.total_claims, 0) * 100.0 / NULLIF(ss.total_sales, 0)), 2) AS claim_rate
FROM store_sales ss
LEFT JOIN store_claims sc 
ON ss.store_id = sc.store_id
ORDER BY claim_rate ASC
;

 -----------------THE END---------------------------------

	