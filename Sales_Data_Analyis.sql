 
select * from sales_data;

-- To find the total_sales_per_year, we will run the below query.

select year(Date) as new_date,sum(total_sales) as total_sales_per_year
from sales_data
group by new_date;

-- To find the top 5 best-selling products based on total sales, use the below query. 

select product_name,sum(total_sales) as total_sales
from sales_data
group by product_name
order by total_sales_per_year desc
limit 5;

-- to Calculate the average order value (total sales per transaction)

select avg(total_sales)
from sales_data;

-- To determine which store location had the highest sales, use the below query

select Store_location ,sum(total_sales) as total_sales
from sales_data
group by Store_location
order by total_sales desc
limit 1;

-- To find the month with the highest revenue each year, use the following query.

with month_rank as (With highest_sales_month as (select year(Date) as year, month(Date) as Month, sum(total_sales) as Total_sales
from sales_data
group by year, month
order by year, month, Total_sales)
select *, 
row_number() over(partition by year order by Total_sales desc) as rank_months
from  highest_sales_month)
select * from month_rank
where rank_months = 1 ;

-- to Rank products within each category by total sales using RANK(), use the following query. 

with ranking_products as (select  Category, product_name,sum(total_sales) as total_sales
from sales_data
group by Product_name, Category
order by category, product_name, total_sales)
select *, 
rank() over (partition by category order by total_sales desc) as rank_products_by_sales
from ranking_products;

 -- To find the cumulative sales per category over time, use the following query.
 
with cummulative_sales_categories as (select  YEAR(Date) as new_year,Category,sum(total_sales) as total_sales
from sales_data
group by new_year, Category
order by new_year, Category)
select *, 
sum(total_sales) over (partition by category order by new_year) as cummulative_sales_over_time
from cummulative_sales_categories;

-- To find highest and lowest total sales transaction for each store, use the below query.

select  store_location,max(Total_Sales) as higest_sales_transaction, min(Total_Sales) as minimum_sales_transaction
from sales_data
group by store_location;

-- To Find the average total sales per customer using PARTITION BY, use the below query.

select Customer_ID,
round(avg(total_sales) over (partition by customer_ID),2) as average_sales_per_customer
from sales_data;

-- In order to Calculate a 7-day moving average of total sales, use the following code;
with sales_moving_average as (select Date,
sum(total_sales) as total_daily_sales
from sales_data
group by Date
order by Date)
select *,
Round(avg(total_daily_sales) over(order by Date rows between 6 preceding and current row),2) as moving_average_7_days
from sales_moving_average;

-- To find customers who have made multiple purchases, use the below query
select customer_ID, count(*) as number_of_orders
from sales_data
group by customer_ID
Having number_of_orders = 1
;

-- To identify products that contributed at least 5% to total revenue, use cross join and CTE to obtain the following result.

with Total_sales_per_product as (select product_Name, sum(total_sales) as total_sales_per_product
from sales_data
group by product_Name),
total_sales as (select sum(total_sales) as total_sales_overall
from sales_data)
select tsp.product_name,(tsp.total_sales_per_product/tos.total_sales_overall) as Percentage_of_sales_to_total
 from  Total_sales_per_product tsp
 cross join total_sales tos
 Having Percentage_of_sales_to_total > 0.050;


-- to Find customers who bought at least one product from every category, use the following Query.
with total_number_of_unique_categories as (select count(Distinct(Category)) as total_categories from sales_data),
total_number_of_unique_categories_per_customer as (select customer_ID, count(Distinct(Category)) as number_of_distinct_category_products_bought_per_customer from sales_data
group by customer_ID)
 select tnc.customer_ID,Round(tnc.number_of_distinct_category_products_bought_per_customer/tn.total_categories,2) as percentage_of_total_categories_bought_from
 from total_number_of_unique_categories tn
 cross join total_number_of_unique_categories_per_customer tnc
where Round(tnc.number_of_distinct_category_products_bought_per_customer/tn.total_categories,2)   = 1.00;

-- to Get all transactions where the product price was above the category’s average price, use the below query

with avg_per_category as (select category, round(avg(unit_price),2) as average_unit_price_per_category from 
sales_data
group by category),
product_price_per_transaction as (select transaction_ID, category,round((unit_price),2) as unit_price from 
sales_data)
select pt.transaction_ID,av.category,av.average_unit_price_per_category, pt.unit_price
from avg_per_category av
join
 product_price_per_transaction pt on pt.category = av.category
 where unit_price > average_unit_price_per_category;
 
-- To find stores that had a sales drop compared to the previous year, use the below query

select * from sales_data;
with total_sales_per_store as (select year(Date) as sales_year, store_location, sum(total_sales) as total_sales
from sales_data
group by store_location, sales_year),
sales_previous_year as (select *, lag(total_sales) over (partition by store_location order by sales_year) as sales_previous_year
from total_sales_per_store)
select * from sales_previous_year
where total_sales < sales_previous_year;


-- To find the percentage of total sales contributed by each category

select * from sales_data;
with total_per_category as (select Category, sum(total_sales) as sales_per_category
from sales_data
group by Category),
total_sales as (select sum(total_sales) as sales_total from sales_data)
select tpc.Category,concat(round((tpc.sales_per_category/ts.sales_total*100),2),'%') as percentage_contributed_per_category
from total_per_category tpc
cross join
total_sales ts;

-- To classify customers as ‘Low’, ‘Medium’, or ‘High Value’ based on their total spending.

WITH customer_spending as (
select customer_ID, sum(Total_Sales) as total_spent from 
sales_data
group by customer_ID)
select customer_ID,total_spent,
case when total_spent > 3500 then 'High Value'
when total_spent between 2000 and 3500 then 'Medium value'
when total_spent < 2000 then 'Low value'
else null end as value_of_customer
from customer_spending 
 ;
 
 -- to  Find the first and last purchase date for each customer.
 
 select customer_id, Min(Date) as first_purchase, max(Date) as last_purchase
 from sales_data
 group by customer_id;
 
-- To find the most frequently purchased product by each customer.

with customer_data as (select customer_ID, Product_name, count(transaction_id) as number_of_transactions
from sales_data
group by customer_ID, Product_name),
most_bought_item as (select customer_ID, product_name, number_of_transactions, 
row_number() over (partition by customer_ID order by number_of_transactions desc) as rank_products
from customer_data)

select * from most_bought_item
where rank_products = 1;


-- To detect any anomalies where the total sales value doesn’t match quantity × unit price, we use the below query.
select transaction_ID, product_name from sales_data
where Abs((quantity * unit_price) - Total_sales) > 0.01;



 
 







