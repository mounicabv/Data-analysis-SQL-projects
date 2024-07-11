Combine orders and customers tables to get more detailed information about each order.

create view order_customer_view as
select c.customer_id, o.order_id,
    c.company_name,
    c.contact_name,
    o.order_date from orders o join customers c
  on o.customer_id= c.customer_id
------------------------------------------------------------------------------

Combine order_details, products, and orders tables to get detailed order information, including the product name and quantity.

create view orderdetail_product_view as
select o.order_id,
    p.product_name,
    od.quantity,
    o.order_date from orders o join order_details od
  on o.order_id= od.order_id join
    products p on od.product_id = p.product_id
--------------------------------------------------------------------------------
Combine employees and orders tables to see who is responsible for each order.

create view orders_employee_view as
select o.order_id,
  e.first_name || ' ' || e.last_name as employee_name,
  o.order_date from orders o join employees e
  on o.employee_id = e.employee_id
---------------------------------------------------------------------------------
1.Ranking Employee Sales Performance -
  Rank employees based on their total sales amount

WITH rank_employee as(
select  e.employee_id,e.first_name || ' ' || e.last_name as employee_name,
    sum(od.unit_price*od.quantity*(1-discount) ) as total_sales
    from employees e join orders o
    on e.employee_id =o.employee_id
    join order_details od
    on o.order_id =od.order_id
    group by e.employee_id
)
select employee_id,employee_name,
RANK() over (order by total_sales desc) as sales_rank
from rank_employee

--------------------------------------------------------------------------
2.Calculate running total of Monthly sales
  
with monthly_sales as(
select DATE_TRUNC('month', Order_Date)::DATE as order_month,
sum(unit_price*quantity*(1-discount) ) as total_sales
from orders o join order_details od
on o.order_id= od.order_id
group by DATE_TRUNC('month', Order_Date)::DATE
)
select order_month,
sum(total_sales) over(order by order_month )as Running_total
  from monthly_sales;
------------------------------------------------------------------------
3.Month over Month sales growth

with monthly_sales as(
select  DATE_TRUNC('month', Order_Date)::DATE as order_month,
    sum(unit_price*quantity*(1-discount) ) as current_month
    from orders o
    join order_details od
    on o.order_id =od.order_id
    group by DATE_TRUNC('month', Order_Date)::DATE
),
previous_month_sales as(
 select *,
    lag(current_month,1) over(order by order_month) as previous_month from monthly_sales
)
select order_month,current_month,previous_month,
(current_month-previous_month)/previous_month*100.0 as growth_rate
from previous_month_sales;

(or)
  
with monthly_sales as(
select  EXTRACT('month' from Order_Date) AS Month, 
           EXTRACT('year' from Order_Date) AS Year,
    sum(unit_price*quantity*(1-discount) ) as current_month
    from orders o
    join order_details od
    on o.order_id =od.order_id
    group by EXTRACT('month' from Order_Date),
           EXTRACT('year' from Order_Date)
),
previous_month_sales as(
 select *,
    lag(current_month,1) over(order by order_month) as previous_month from monthly_sales
)
select Year,Month,
(current_month-previous_month)/previous_month*100.0 as growth_rate
from previous_month_sales;

----------------------------------------------------------------------------------------------
4.Identify High Value customers i.e customers with above-average order values
with high_value_customer as(
    select  o.customer_id,o.Order_ID, 
   
    sum(unit_price*quantity*(1-discount)) as total_sales
   from orders o
    join order_details od
    on o.order_id= od.order_id
    group by o.customer_id,o.Order_ID
)
select customer_id,order_id,total_sales,
case when total_sales>avg(total_sales) over() then 'Above Average'
     else 'Below Average'
     end as value_category
     from high_value_customer limit 10

count how many orders are 'Above Average' for each customer.

with high_value_customer as(
    select  o.customer_id,o.Order_ID, 
   
    sum(unit_price*quantity*(1-discount)) as total_sales
   from orders o
    join order_details od
    on o.order_id= od.order_id
    group by o.customer_id,o.Order_ID
),
avg_category as(
select customer_id,order_id,total_sales,
case when total_sales>avg(total_sales) over() then 'Above Average'
     else 'Below Average'
     end as value_category
     from high_value_customer
)
select customer_id,count(order_id)
from avg_category
where value_category = 'Above Average'
group by customer_id

--------------------------------------------------------------------------------------
5.Find Percentage of Sales for Each Category
with product_category as(
    select  c.category_id,c.category_name,
    sum(p.unit_price*quantity*(1-discount)) as total_sales
   from order_details od join products p
    on od.product_id= p.product_id
    join categories c
    on p.category_id = c.category_id
    group by c.category_id,c.category_name
)
select category_id,category_name,
total_sales/sum(total_sales) over ()*100.0 as sales_percentage
    from product_category
    order by sales_percentage

----------------------------------------------------------------------------------
6.Find top products per category

with product_category as(
    select  p.category_id,p.product_id,p.product_name,
    sum(p.unit_price*quantity*(1-discount)) as total_sales
   from order_details od join products p
    on od.product_id= p.product_id
    group by p.category_id,p.product_id
),
rank_category as(
select *,
row_number() over (partition by category_id order by total_sales desc)as rank
    from product_category
 )
 select category_id,product_id,product_name,total_sales
 from rank_category where rank<=3
-------------------------------------------------------------------------
7.Identify the top 20% of customers by total purchase volume.

with top_customers as(
    select  o.customer_id,c.contact_name as customer_name,
    sum(unit_price*quantity*(1-discount)) as total_purchases
   from orders o
    join order_details od
    on o.order_id= od.order_id
    join customers c on c.customer_id=o.customer_id
    group by o.customer_id,c.contact_name
),
rank_customer as(
select *,    
ntile(5) over( order by total_purchases desc) as percentile 
    from top_customers
)
select customer_name,total_purchases
from rank_customer 
where percentile =1
    









