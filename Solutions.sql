 Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select sum(total) as totalrevenue
      --
FROM sale
WHERE EXTRACT(YEAR FROM sale_date) = 2023
  AND EXTRACT(QUARTER FROM sale_date) = 4;


select c1.city_name, 
sum(s.total) as totalrevenue    
FROM sale as s 
join customers as c
on s.customer_id = c.customer_id 
join city as c1
on c1.city_id = c.city_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2023
  AND EXTRACT(QUARTER FROM s.sale_date) = 4
 group by c1.city_name
order by 2  desc 


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as uniquecustomr
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.uniquecustomer
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name



-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM -- table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
	-- ORDER BY 1, 3 DESC
) as t1
WHERE rank <= 3


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as consumers
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

with avgtable
as 
(select c1.city_name,
sum(s.total) as totalrevenue,COUNT(distinct s.customer_id)as totalcoustmr,
round(sum(s.total)/COUNT(distinct s.customer_id)) as avgsale    
from sale as s
join customers as c
on s.customer_id = c.customer_id
join city as c1
on c1.city_id = c.city_id
group by 1
order by 2 desc
),
neededtable
as 
(select city_name,
estimated_rent
from city)
select nd.city_name,
nd.estimated_rent,
at.avgsale,
at.totalcoustmr,
round(nd.estimated_rent/at.totalcoustmr) as avgrentperhead 
from neededtable as nd
join avgtable as at
on at.city_name=nd.city_name
order by 5 desc


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with monthratio
as 
(select city_name,
extract(month from sale_date) as sellingmnth,
extract(year from sale_date) as sellingyear,
sum(total) as revenue
from sale as s 
join customers as c
on s.customer_id=c.customer_id
join city as c1
on c.city_id=c1.city_id
group by 1,2,3
order by 1, 3,2 ),

breakdownqry as
(select city_name,
sellingmnth,
sellingyear,
revenue,
LAG(revenue,1) over(partition by city_name order by sellingyear ,sellingmnth  ) as lastmnthrevenue
from monthratio)

select city_name,
sellingmnth,
sellingyear,
revenue,
lastmnthrevenue,
round((revenue-lastmnthrevenue)/lastmnthrevenue*100) as ratio
from breakdownqry
where lastmnthrevenue is not null


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



with avgtable
as 
(select c1.city_name,
sum(s.total) as totalrevenue,
COUNT(distinct s.customer_id)as totalcoustmr,
round(sum(s.total)/COUNT(distinct s.customer_id)) as avgsale    
from sale as s
join customers as c
on s.customer_id = c.customer_id
join city as c1
on c1.city_id = c.city_id
group by 1
order by 2 desc
),
neededtable
as 
(select city_name,
estimated_rent,
(population *0.25)/1000000 as custmpermillions
from city)
select nd.city_name,
nd.estimated_rent,
at.avgsale,
at.totalrevenue,
nd.custmpermillions,
at.totalcoustmr,
round(nd.estimated_rent/at.totalcoustmr) as avgrentperhead 
from neededtable as nd
join avgtable as at
on at.city_name=nd.city_name
order by 5 desc

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.



