/*  
OLIST ECOMMERCE BUSINESS INSIGHT ANALYSIS
Author: Chioma Isaiah

This is an exploratory data analysis on a Brazilian Ecommerce Public Dataset by Olist
The dataset is available on Kaggle - https://www.kaggle.com/olistbr/brazilian-ecommerce
This dataset contains over 100,000 orders with products, customers, shipping, price, payment, and review information


Dataset Tables:
olist_orders_dataset was renamed to Orders
olist_order_items_dataset was renamed to Orders_Items
olist_order_reviews_dataset was renamed to Reviews
olist_sellers_dataset was renamed to Sellers
olist_customers_dataset was renamed to Customers
olist_products_dataset was renamed to Products
olist_payment_dataset was renamed to Order_Payments


My Analysis is divided into sections that derives insights on the various areas of the ecommerce business:
Data Preparation
Order Analysis
Sellers Analysis
Customers Analysis
Product Analysis
Payment Analysis
Shipping/Delivery/Freight Analysis
Review/Satisfaction Analysis
*/



-- ***************************************** DATA PREPARATION *****************************************

-- Replace the underscore in product_category_name with a whitespace
UPDATE Products
SET product_category_name = REPLACE(product_category_name,'_',' ') 


-- Replace the underscore in product_category_name_translation with a whitespace
UPDATE Product_Category_Name_Translation
SET product_category_name = REPLACE(product_category_name,'_',' '),
	product_category_name_english = REPLACE(product_category_name_english,'_',' ')






-- ********************************************* ORDER ANALYSIS *************************************

-- 1. What proportion of total orders placed on the site are fulfilled?
Select 
	o.order_status as 'Order Status', 
	count(o.order_id) as 'Count of Orders', 
	count(o.order_id)*100/sum(count(o.order_id)) over() as 'Proportion of Orders'
From 
	Orders as o
Group by 
	o.order_status
/* INSIGHT: 
	Over 98% of total orders have been delivered or shipped. Less than 1% were canceled or unavailable.
	This implies that most of the customer orders get fulfilled */



-- 2. Evaluate number of orders for each month in the dataset
Select 
	year(o.order_purchase_timestamp) as 'Year', 
	month(o.order_purchase_timestamp) as 'Month',
	count(o.order_id) as 'Count of Orders'
From 
	Orders as o 
Group by 
	year(o.order_purchase_timestamp), 
	month(o.order_purchase_timestamp)
Order by 
	year(o.order_purchase_timestamp), 
	month(o.order_purchase_timestamp)
/* INSIGHT: 
	Dataset contains orders from Sep 2016 to Oct 2018. 
	There appears to be incomplete data in 2016 and in Sep and Oct of 2018, so we may exclude this period from any timeline analysis */



/* 3. Has there been growth in the number of orders placed over the time period?
	  The focus here is on comparing number of orders on Jan-Aug 2017 to Jan-Aug 2018 by month i.e. Jan 2017 vs Jan 2018, etc */
Select
	sq.Year,
	sq.Month,
	sq.Orders_Count as 'Count of Orders',
	sq.Lag_Count as 'Count of Prior Year Orders',
	((sq.Orders_Count-sq.Lag_Count)*100)/nullif(sq.Lag_Count,0) as 'YOY Growth'
	From 
		(Select 
			year(o.order_purchase_timestamp) as 'Year', 
			month(o.order_purchase_timestamp) as 'Month',
			count(o.order_id) as Orders_Count,
			lag(count(o.order_id),12) over (order by year(o.order_purchase_timestamp), month(o.order_purchase_timestamp)) as Lag_Count
		From 
			Orders as o 
		Group by 
			year(o.order_purchase_timestamp), 
			month(o.order_purchase_timestamp)) as sq 
Where
	sq.Year = 2018 and
	sq.Month <= 8
/* INSIGHT: 
	There is a very large YOY growth on the number of orders placed. */



-- 4. On what weekday are the most orders placed?
Select 
	datename(dw,o.order_purchase_timestamp) as 'Week Day',
	count(o.order_id) as 'Count of Orders',
	count(o.order_id)*100/sum(count(o.order_id)) over() as 'Proportion of Orders'
From 
	Orders as o 
Group by 
	datename(dw,o.order_purchase_timestamp)
Order by 
	count(o.order_id) desc
/* INSIGHT:
	Customers placed the more orders on Mondays and less orders on the Weekends	*/



-- 5. What time of the day are the most orders placed?
Select 
	case 
		when datepart(hour,o.order_purchase_timestamp) between 5 and 12 then 'Morning'
		when datepart(hour,o.order_purchase_timestamp) between 12 and 17 then 'Afternoon'
		else 'Evening'
	end as 'Time of Day',
	count(o.order_id) as 'Count of Orders'
From 
	Orders as o 
Group by 
	case 
		when datepart(hour,o.order_purchase_timestamp) between 5 and 12 then 'Morning'
		when datepart(hour,o.order_purchase_timestamp) between 12 and 17 then 'Afternoon'
		else 'Evening'
	end
Order by 
	count(o.order_id) desc
/* INSIGHT: 
	Most orders are placed in the evening and orders are placed least in the morning	*/




-- 6. What exact hour of the day are the most orders placed?
Select 
	datepart(hour,o.order_purchase_timestamp) as 'Hour of Day',
	count(o.order_id) as 'Count of Orders'
From 
	Orders as o 
Group by 
	datepart(hour,o.order_purchase_timestamp)
Order by 
	count(o.order_id) desc
/* INSIGHT: 
	Although most orders are made in the evening, the hours with the busiest traffic are in the late morning/afternoon - 4pm, 11am, 2pm, 1pm and 3pm.
	12am to 7am have the least orders does not appear surprising  */






-- ********************************************* SELLERS ANALYSIS *********************************************

-- 1. What State and City have the most sellers in term of sales value?
Select 
	s.seller_state as 'State', 
	s.seller_city as 'City', 
	count(distinct s.seller_id) as 'Number of Seller',
	count(distinct o.order_id) as 'Count of Orders', 
	cast(sum(oi.price) as money) as 'Total Order Amount'
From
	Sellers as s left join
	Order_items as oi on (s.seller_id = oi.seller_id) left join
	Orders as o on (oi.order_id = o.order_id) 
Group by 
	s.seller_state,
	s.seller_city
Order by 
	sum(oi.price) desc, 
	count(distinct o.order_id) desc
/* INSIGHT: 
	The top sales are from sellers in the city of  Sao Paulo with 694 distinct sellers and over R$2.7MM in total sales	
	Most of the top sales are from seller within the state of SP (both Sao Paulo city and other cities in SP) */



-- 2. Who are the top 20 sellers by sales value and where are they located?
Select Top 20
	right(s.seller_id,6) as 'Seller ID', --The last 6 characters of each seller's ID is unique
	s.seller_state as 'State', 
	s.seller_city as 'City',
	count(distinct o.order_id) as 'Count of Orders', 
	cast(sum(oi.price) as money) as 'Total Order Amount'
From 
	Sellers as s join
	Order_items as oi on (s.seller_id = oi.seller_id) join
	Orders as o on (oi.order_id = o.order_id) 
Group by 
	right(s.seller_id,6),
	s.seller_state, 
	s.seller_city
Order by 
	sum(oi.price) desc, 
	count(distinct o.order_id) desc
/* INSIGHTS:  
	The top seller is the seller with ID ending as '3b52b2', who is located in Guatiba SP and has made as of R$229K
	Most of the top sellers are in the state SP, but most of them live outside of Sao Paulo. None of the top 7 sellers are in the city of Sao Paulo
	It is interesting that despite the fact that most sales come from sellers in Sao Paulo, most of the top sellers not in Sao Paulo	*/



-- 3. Have the number of sellers who sold products increased over time?
Select 
	year(o.order_purchase_timestamp) as 'Year', 
	month(o.order_purchase_timestamp) as 'Month',
	count(distinct s.seller_id) as 'Number of Sellers',
	count(o.order_id) as 'Count of Orders',
	round(sum(oi.price), 2) as 'Value of Orders'
From 
	Orders as o left join
	Order_Items as oi on (o.order_id = oi.order_id) left join
	Sellers as s on (oi.seller_id = s.seller_id)
Group by 
	year(o.order_purchase_timestamp), 
	month(o.order_purchase_timestamp)
Order by 
	year(o.order_purchase_timestamp), 
	month(o.order_purchase_timestamp)
/* INSIGHTS:  
	The number of sellers have been trending upwards over the time period analyzed.
	However, despite the growth in the number of sellers, there was been a decline in the number and value of orders made since June 2018.
	It would be interesting to analyze further to determine why sales and number of orders dropped in the last set of month despite the growth in the number of sellers */






-- ********************************************* CUSTOMER ANALYSIS *********************************************

-- 1. What State and City are have the most customers in term of sales value?
Select 
	c.customer_state as 'State', 
	c.customer_city as 'City', 
	count(distinct c.customer_unique_id) as 'Number of Customers',
	count(distinct o.order_id) as 'Count of Orders',
	cast(sum(oi.price) as money) as 'Total Order Amount'
From 
	Customers as c left join
	Orders as o on (c.customer_id = o.customer_id) left join
	Order_items as oi on (o.order_id = oi.order_id)
Group by 
	c.customer_state, 
	c.customer_city
order by 
	sum(oi.price) desc, 
	count(distinct o.order_id) desc
/* INSIGHT:  
	Again, the top total purchases are from customers in the city of Sao Paulo with almost 15K distinct customers and over R$1.9MM in total purchases made	*/



	-- 3. Have the number of customer who made orders increased over time and how has this affected purchases?
Select 
	year(o.order_purchase_timestamp) as 'Year', 
	month(o.order_purchase_timestamp) as 'Month',
	count(distinct c.customer_unique_id) as 'Number of Customers',
	count(o.order_id) as 'Count of Orders',
	round(sum(oi.price), 2) as 'Value of Orders'
From 
	Orders as o left join
	Customers as c on (o.customer_id= c.customer_id) left join
	Order_Items as oi on (o.order_id = oi.order_id) 	
Group by 
	year(o.order_purchase_timestamp), 
	month(o.order_purchase_timestamp)
Order by 
	year(o.order_purchase_timestamp), 
	month(o.order_purchase_timestamp)
/* INSIGHTS:  
	The number of customers generally increased over time untill June 2018 where number of customers dropped by 10%.
	Sales also dropped by slightly over 10% in June 2018. It appears there is a correlation between the number of customers and sales.
	This explain the reduction in sales despite growth in the number of sellers  */




-- 3. Who are the top 20 customers by sales value and where are they located?
Select Top 20
	right(c.customer_unique_id,8) as 'Customer ID',  --The last 8 characters of each seller's ID is unique
	c.customer_state as 'State',
	c.customer_city as 'City', 
	count(distinct o.order_id) as 'Count of Orders',
	cast(sum(oi.price) as money) as 'Total Order Amount'
From 
	Customers as c left join
	Orders as o on (c.customer_id = o.customer_id) left join
	Order_items as oi on (o.order_id = oi.order_id)
Group by 
	right(c.customer_unique_id,8),
	c.customer_state, 
	c.customer_city
order by 
	sum(oi.price) desc, 
	count(distinct o.order_id) desc
/* INSIGHTS: 
	The top customer is the customer with ID ending as '5afaa872', who is located in Rio de Janeiro, RJ and made only one order worth $13K
	Most of the top customers are not in SP. However, the top customers do not have large orders
	Since, most of the top customers by value made only one order, I'll analyze how many repeat customers orders there are within the period analyzed	*/



-- 4. How many customers are repeat customers or one-time buyers?
With cte_repeat_customers as (	
	Select 
		right(c.customer_unique_id,8) as Customer_ID,  --The last 8 characters of each seller's ID is unique
		count(distinct o.order_id) as 'Count of Orders',
		cast(sum(oi.price) as money) as 'Total Order Amount'
	From 
		Customers as c left join
		Orders as o on (c.customer_id = o.customer_id) left join
		Order_items as oi on (o.order_id = oi.order_id)
	Group by 
		right(c.customer_unique_id,8)
		)
Select 
	crc.[Count of Orders],
	count(crc.Customer_ID) as 'Number of Customers',
	count(crc.Customer_ID)*100/sum(count(crc.Customer_ID)) over() as 'Proportion of Customers',
	sum(crc.[Total Order Amount]) as 'Total Order Amount',
	sum(crc.[Total Order Amount])*100/sum(sum(crc.[Total Order Amount])) over() as 'Proportion of Sales'
From
	cte_repeat_customers as crc
Group by
	crc.[Count of Orders]
Order by
	crc.[Count of Orders] desc
/* INSIGHTS: 
	Over 96% of the customers who made orders did not return to make more orders. Most of the buyers are one-time customers
	94% of total sales value on Olist are from one-time customers and another 5% from customers who have place only two orders
	It is interesting that less than 1% of sales are from customers who made orders more than 2 times over the time period analyzed. 	
	
	From the customer analysis, I have recieved great insight on how the business might improve its sales. The number of customers significantly affect sales.
	And the site is currently no retaining customers. Implementing strategies to retain buyers and customer loyalty program will help boost sales on the site   */


	




-- ********************************************* PRODUCT ANALYSIS *********************************************

-- 1. What are the top selling product category by sales value?
Select
	iif(pt.product_category_name_english is null,'No Category', pt.product_category_name_english) as 'Product Category',
	count(distinct o.order_id) as 'Count of Orders',
	cast(sum(oi.price) as money) as 'Total Sales Amount'
From
	Products as p left join
	Product_Category_Name_Translation as pt on (p.product_category_name = pt.product_category_name) left join
	Order_Items as oi on (p.product_id = oi.product_id) left join
	Orders as o on (oi.order_id = o.order_id)
Group by
	iif(pt.product_category_name_english is null,'No Category', pt.product_category_name_english)
Order by
	sum(oi.price) desc
/* INSIGHT:  
	The top selling product by sales volume is Health Beauty products with over R$1.26MM in sales within the period analyzed	*/




-- 2. What are the top selling product category based on number of orders?
Select
	iif(pt.product_category_name_english is null,'Others', pt.product_category_name_english) as 'Product Category',
	count(distinct o.order_id) as 'Count of Orders',
	cast(sum(oi.price) as money) as 'Total Sales Amount'
From
	Products as p left join
	Product_Category_Name_Translation as pt on (p.product_category_name = pt.product_category_name) left join
	Order_Items as oi on (p.product_id = oi.product_id) left join
	Orders as o on (oi.order_id = o.order_id)
Group by
	iif(pt.product_category_name_english is null,'Others', pt.product_category_name_english)
Order by
	count(distinct o.order_id) desc
/* INSIGHT:  
	The top selling product based on the number of orders placed is Bed Bath Table, with 9,417 orders placed within the period analyzed		*/




-- 3. What are the top 20 specific products ordered, and who are the sellers of the top products?
Select
	left(p.product_id,8) as 'Product',		-- The first 8 characters of each product ID is unique
	iif(pt.product_category_name_english is null,'No Category', pt.product_category_name_english) as 'Product Category',
	right(s.seller_id,6) as 'Seller ID',   -- The last 6 characters of each seller's ID is unique
	s.seller_state as 'State',
	s.seller_city as 'City',
	count(distinct o.order_id) as 'Count of Orders',
	cast(sum(oi.price) as money) as 'Total Sales Amount'
From
	Products as p join
	Order_Items as oi on (p.product_id = oi.product_id) join
	Orders as o on (oi.order_id = o.order_id) join
	Sellers as s on (oi.seller_id = s.seller_id) left join
	Product_Category_Name_Translation as pt on (p.product_category_name = pt.product_category_name) 
Group by
	left(p.product_id,8),
	iif(pt.product_category_name_english is null,'No Category', pt.product_category_name_english),
	right(s.seller_id,6),
	s.seller_state,
	s.seller_city
Order by
	count(distinct o.order_id) desc
/* INSIGHT:  
	The most ordered product is 99a4788c (a Bed Bath table). Its seller is Seller ID 493884, who is located in Ibitingas SP. 
	There has been 461 distinct orders placed on the top product worth R$42.5K		*/



-- 4. What are the top 20 specific products based on total sales value, and who are the sellers of the top products?
Select
	left(p.product_id,8) as 'Product',		-- The first 8 characters of each product ID is unique
	iif(pt.product_category_name_english is null,'No Category', pt.product_category_name_english) as 'Product Category',
	right(s.seller_id,6) as 'Seller ID',   -- The last 6 characters of each seller's ID is unique
	s.seller_state as 'State',
	s.seller_city as 'City',
	count(distinct o.order_id) as 'Count of Orders',
	cast(sum(oi.price) as money) as 'Total Sales Amount'
From
	Products as p join
	Order_Items as oi on (p.product_id = oi.product_id) join
	Orders as o on (oi.order_id = o.order_id) join
	Sellers as s on (oi.seller_id = s.seller_id) left join
	Product_Category_Name_Translation as pt on (p.product_category_name = pt.product_category_name) 
Group by
	left(p.product_id,8),
	iif(pt.product_category_name_english is null,'No Category', pt.product_category_name_english),
	right(s.seller_id,6),
	s.seller_state,
	s.seller_city
Order by
	sum(oi.price) desc
/* INSIGHT: 
	Based on sales value, the top product is bb50f2e2, a Health Beauty product. It has 187 orders worth R$63.8K
	Its seller is Seller ID 3b70c4, who is located in Sao Bernardo do Campo SP. 
	We understand from the data that the products with the most orders does not have the most total sales value, which is usually the case in a lot of businesses	*/





-- ********************************************* PAYMENT ANALYSIS *********************************************

-- 1. What method of payment is most used?
Select
	op.payment_type as 'Method of Payment',
	count(op.order_id) as 'Number of Times Used',
	count(op.order_id)*100/sum(count(op.order_id)) over () as 'Proportion'
From
	Order_Payments as op join
	Orders as o on (op.order_id = o.order_id)
Where
	o.order_status = 'delivered'
Group by
	op.payment_type
/* INSIGHT: 
	74% of payments made on orders delivered were made with credit cards. Only 1% of payments were made with debit cards.	*/



-- 2. In how many installments are payments usually made?
Select
	op.payment_installments as 'Number of Installments',
	count(distinct op.order_id) as 'Count of Orders',
	count(distinct op.order_id)*100/sum(count(distinct op.order_id)) over () as 'Proportion'
From
	Order_Payments as op
Group by
	op.payment_installments
Order by
	count(distinct op.order_id) desc
/* INSIGHT: 
	About 48% of all orders are paid in one installment.	*/



-- 3. Do customers with multiple installments pay a premium on their orders?

	-- First, Creating a temp table for the max installments and total value of each distinct order
	-- I am using a temp table rather than a CTE because I'll need to refer to this temp table in another subsequent query
If OBJECT_ID('tempdb..#TT_Cust_Payments') is not null 
	DROP TABLE 	#TT_Cust_Payments
		Select distinct 
			order_id, 
			max(payment_installments) as payment_installments, 
			sum(payment_value) as Cust_Payment 
		Into #TT_Cust_Payments
		From 
			Order_Payments
		Group by 
			order_id 

Select
	o.order_id as 'Order ID',
	cp.payment_installments as 'Number of Installments',
	cp.cust_payment as 'Customer Payment',
	sum(oi.price+oi.freight_value) as 'Total Invoice Amount',  -- Adding up price and freight as invoice total
	cast(cp.cust_payment - sum(oi.price+oi.freight_value) as money)  as 'Premium/(Discount)',
	round((cp.cust_payment - sum(oi.price+oi.freight_value))*100/sum(oi.price+oi.freight_value),2) as 'Premium/(Discount) Percent'
From
	Orders as o left join
	Order_items as oi on (o.order_id = oi.order_id) left join
	#TT_Cust_Payments as cp on (o.order_id=cp.order_id)
where
	o.order_status = 'delivered' 
Group by
	o.order_id,
	cp.payment_installments,
	cp.cust_payment
Order by
	(cp.cust_payment - sum(oi.price+oi.freight_value))*100/sum(oi.price+oi.freight_value) desc 
/* INSIGHTS: 
	Customers who paid on premuim (amount above order price and freight) on their orders were making payments in multiple installments
	A few customers (not significant in number of orders) had discounts or made less payments
	Majority of customers who made payments in one installment were not charged any premium		*/



-- 4. What is the average premium applied on orders based on the number of payment installments?
	  -- I am going to group the payment installments into 5 bins
	  -- This CTE is to calculate the premium for each line order before grouping into bins to get the average premium of each bin
With cte_premium as (
	Select
		o.order_id as 'Order ID',
		cp.payment_installments,
		cp.cust_payment - sum(oi.price+oi.freight_value) as 'Premium',
		(cp.cust_payment - sum(oi.price+oi.freight_value))*100/sum(oi.price+oi.freight_value) as 'Premium_Percent'
	From
		Orders as o left join
		Order_items as oi on (o.order_id = oi.order_id) left join
		#TT_Cust_Payments as cp on (o.order_id=cp.order_id)
	where
		o.order_status = 'delivered' 
	Group by
		o.order_id, cp.payment_installments, cp.cust_payment
															)
Select
	case 
		when cte_premium.payment_installments <= 10 then cte_premium.payment_installments
		when cte_premium.payment_installments <= 15 then '10-15'
		when cte_premium.payment_installments <= 20 then '16-20'
		else 'Above 20'
	end as 'Payment Installments',             --- grouping the number of payment installments into bins
	cast(Avg(cte_premium.premium) as money) as Avg_Premium,
	round(Avg(cte_premium.premium_percent),2) as Avg_Premium_Percent
From 
	cte_premium
Group by 
	case 
		when cte_premium.payment_installments <= 10 then cte_premium.payment_installments
		when cte_premium.payment_installments <= 15 then '10-15'
		when cte_premium.payment_installments <= 20 then '16-20'
		else 'Above 20'
	end
Order by
	Avg(cte_premium.premium_percent)
/* INSIGHTS:  
	Order paid in 1 or 2 installment had no additional charge on an average and those with above 20 installments paid a premium of 2.35%
	On an average, the more payment installment made, the higher the premium. This meets my expectation - Paying later usually costs more	*/





-- ***************************************** SHIPPING/DELIVERY/FREIGHT ANALYSIS *****************************************

-- 1. What is the average shipping fee (freight) by Sellers' State?

Select 
	s.seller_state as 'State',
	cast(Avg(oi.freight_value) as money) as 'Average Freight'
From
	Order_Items as oi left join
	Sellers as s on (oi.seller_id = s.seller_id)
Group by
	s.seller_state
Order by
	Avg(oi.freight_value) 
/* INSIGHT: 
	Shipping cost is cheapest where sellers are located in SP, and most expensive when sellers are located in RO	*/



-- 2. What is the average shipping fee (freight) by Customers' State?
Select 
	c.customer_state 'State',
	cast(Avg(oi.freight_value) as money) as 'Average Freight'
From
	Order_Items as oi left join
	Orders as o on (oi.order_id = o.order_id) left join
	Customers as c on (o.customer_id = c.customer_id )
Group by
	c.customer_state
Order by
	Avg(oi.freight_value) 
/* INSIGHT: 
	Shipping cost is cheapest where customers are located in SP, and most expensive when sellers are located in RR	*/



-- 3. What proportion of orders on Olist offered free shipping
	  -- For this analysis, I am going to regard free shipping as any shipping cost of R$1.00 or less
Select 
	iif(oi.freight_value <= 1,'Free','Paid') as 'Shipping Type',
	count(distinct oi.order_id) as 'Count of Orders', 
	count(distinct oi.order_id)*100/sum(count(distinct oi.order_id)) over() as 'Proportion'
From	
	Order_Items as oi
Group by 
	iif(oi.freight_value <= 1,'Free','Paid')
/* INSIGHT: 
	Only 1% of all orders made are delivered for free. 99% of orders have an additional shipping cost */



-- 4a. How long does it take from orders to be delivered? i.e. Order Date vs Delivery Date
-- 4b. Is the average freight higher for quicker deliveries?
Select 
	case when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 5 then 'Less than 5 Days'
		 when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 10 then '6-10 Days'
		 when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 15 then '11-15 Days'
		 when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 20 then '16-20 Days'
		else 'More than 20 Days'
	end as 'Days for Delivery',
	count(distinct o.order_id) as 'Count of Orders', 
	count(distinct o.order_id)*100/sum(count(distinct o.order_id)) over() as 'Proportion',
	round(avg(oi.freight_value),2) as 'Average Freight'
From
	Orders as o left join
	Order_Items as oi on (o.order_id = oi.order_id)
Where 
	o.order_status = 'delivered'
Group by
	case when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 5 then 'Less than 5 Days'
		 when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 10 then '6-10 Days'
		 when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 15 then '11-15 Days'
		 when datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date) <= 20 then '16-20 Days'
		else 'More than 20 Days'
	end
Order by avg(oi.freight_value)
/* INSIGHTS:
	About 17% of deliveries are made within 5 days of orders, and 34% within 6-10 days. 
	Only 13% of all order are delivered in more than 20 days of order date
	A very interesting finding is that on an average the deliveries made earlier costs lesser in average shipping cost 
	I will explore this further by looking into the delivery time and average freight by product category and by customer location */



-- 5. Analysis Delivery Days and Average Freight rate based on Product Category
Select 
	pt.product_category_name_english as 'Product Category',
	avg(datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date)) as 'Average Delivery Days',
	round(avg(oi.freight_value),2) as 'Average Freight'
From
	Orders as o left join
	Order_Items as oi on (o.order_id = oi.order_id) left join
	Products as p on (oi.product_id = p.product_id) left join
	Product_Category_Name_Translation  as pt on (p.product_category_name = pt.product_category_name)
Where 
	o.order_status = 'delivered'
Group by
	pt.product_category_name_english
Order by avg(oi.freight_value) desc
/* INSIGHTS:
	Office Furniture have the slowest deliveries made an average of 20 days after orders are places
	Art and Craftmanship products have the quickest delivery with average delivery period of 5 days within order date
	Computers have the most expensive average freight rate (R$48.57) while children's clothes have the lowest average freight rate (R$11.25)
	This does not really explain to me why quicker deliveries have lower average freight cost */



-- 6. Analysis Delivery Days and Average Freight rate based on Location of Customer
Select 
	c.customer_state  as 'State',
	avg(datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date)) as 'Average Delivery Days',
	round(avg(oi.freight_value),2) as 'Average Freight'
From
	Orders as o left join
	Order_Items as oi on (o.order_id = oi.order_id) left join
	Customers as c on (o.customer_id = c.customer_id)
Where 
	o.order_status = 'delivered'
Group by
	c.customer_state
Order by avg(datediff(D, o.order_purchase_timestamp, o.order_delivered_customer_date))
/* INSIGHTS:
	SP has the quickest delivery of 8 days average and the cheapest freight rate. 
	On the other hand, the slowest average delivery and one of the most expensive shipping costs are those made to customer in RR 
	The location of customers somehow explain why I earlier noticed that quicker deliveries had lower average freight rate
	This makes sense with our earlier discoveries are most seller and customers are located in the state SP  */



-- 7. How accurate is the estimated delivery date on the order? i.e. Estimated Delivery Date vs Actual Delivery Date
Select 
	case when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) < -7 then 'More than 1 Week Earlier'
		 when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) <= -1 then 'Days Earlier'
		 when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) = 0 then 'Exact Estimated Day'
		 when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) < 7 then 'Days Later'
		else 'More than 1 Week Later'
	end as 'Days for Delivery',
	count(distinct o.order_id) as 'Count of Orders', 
	count(distinct o.order_id)*100/sum(count(distinct o.order_id)) over() as 'Proportion'
From
	Orders as o
Where 
	o.order_status = 'delivered'
Group by
	case when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) < -7 then 'More than 1 Week Earlier'
		 when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) <= -1 then 'Days Earlier'
		 when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) = 0 then 'Exact Estimated Day'
		 when datediff(D, o.order_estimated_delivery_date, o.order_delivered_customer_date) < 7 then 'Days Later'
		else 'More than 1 Week Later'
	end
/* INSIGHTS:
	More than 84% of orders are delivered more than 5 days ealier than the estimated delivery date. 
	Only about 5% are delivered later than expected  */






-- ***************************************** REVIEW/SATIFACTION ANALYSIS *****************************************

-- 1. Analysis of the rating scores on all orders
Select 
	r.review_score as 'Review Score', 
	count(distinct o.order_id) as 'Count of Orders', 
	count(distinct o.order_id)*100/sum(count(distinct o.order_id)) over() as 'Proportion or Orders'
From 
	Orders as o left join
	Reviews as r on (o.order_id = r.order_id)
Group by 
	r.review_score
/* INSIGHTS:
	First, most of the customers leave reviews on order. Only less than 1% of orders were not reviewed
	57% of order received a 5-star review and 19% a 4-star. 11% of order received a 1-star review and 3% a 2-star.	*/




-- 2. What Product Category has the best average ratings
Select 
	pt.product_category_name_english as 'Product Category',
	count(r.review_score) as 'Count of Reviews',
	avg(convert(decimal, r.review_score)) as 'Average Rating'
From 
	Orders as o left join
	Order_Items as oi on (o.order_id = oi.order_id) left join
	Products as p on (oi.product_id = p.product_id) left join
	Product_Category_Name_Translation  as pt on (p.product_category_name = pt.product_category_name) left join
	Reviews as r on (o.order_id = r.order_id)
Where 
	o.order_status = 'delivered'
Group by 
	pt.product_category_name_english 
Order by
	avg(convert(decimal, r.review_score)) desc
/* INSIGHTS:
	Fashion Children's Clothes has a perfect average rating of 5.0, although it has been reveiwed only 7 time
	Next top rated product category is CDs DVDs Musicals, Books General Interest, and Books Imported.
	The worst performing (rated) category is Security & Services, Diapers and Hygiene, and Officee Furniture.	*/





-- Please view the insights on a Tableau Dashboard at 
-- https://public.tableau.com/app/profile/chioma.isaiah/viz/OlistEcommerceDashboard_16439478675440/Overview?publish=yes
-- View full project on my Portfolio at www.chiomaisaiah.com


