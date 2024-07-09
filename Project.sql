
Scale Model Cars Database
--------------------------------------------------------------------------------------
 
Q1 :Write a query to display the following table:
Select each table name as a string.
Select the number of attributes as an integer (count the number of attributes per table).
Select the number of rows using the COUNT(*) function.
Use the compound-operator UNION ALL to bind these rows together.

Answer:
SELECT 'Customers' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('customers'))
as number_of_attributes,count(*) AS number_of_rows FROM customers
UNION ALL
SELECT 'Payments' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('payments'))
as number_of_attributes,count(*) AS number_of_rows FROM payments
UNION ALL
SELECT 'Products' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('products'))
as number_of_attributes,count(*) AS number_of_rows FROM products
UNION ALL
SELECT 'ProductLines' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('productlines'))
as number_of_attributes,count(*) AS number_of_rows FROM productlines
UNION ALL
SELECT 'OrderDetails' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('orderdetails'))
as number_of_attributes,count(*) AS number_of_rows FROM orderdetails
UNION ALL
SELECT 'Employees' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('employees'))
as number_of_attributes,count(*) AS number_of_rows FROM employees
UNION ALL
SELECT 'Offices' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('offices'))
as number_of_attributes,count(*) AS number_of_rows FROM offices
UNION ALL
SELECT 'Orders' AS table_name,
(SELECT count(*) FROM PRAGMA_TABLE_INFO('orders'))
as number_of_attributes,count(*) AS number_of_rows FROM orders
------------------------------------------------------------------------------------
Q2: Which Products Should We Order More of or Less of?

low stock=SUM(quantityOrdered)/quantityInStock
 product performance=SUM(quantityOrdered×priceEach)

Ans:
with cte_low_stock as(
select p.productCode,
    Round((select sum(o.quantityOrdered)*1.0 from orderdetails o 
where p.productCode=o.productCode)/p.quantityInStock,2) as restock from products p
group by p.productCode
order by restock desc limit 10
),
cte_product_perform as( 
select cl.productCode,
(select round(sum(o.quantityOrdered*o.priceEach),2)
from orderdetails o
where cl.productCode=o.productCode) as product_performance 
from cte_low_stock cl
group by cl.productCode 
order by product_performance desc limit 10
)
select p.productName,p.productLine
from  products p
where p.productCode in (
    select productCode from cte_product_perform )
--------------------------------------------------------------------
Q3. Write a query to find the top five VIP customers.
Ans:
with cte as(
select o.customerNumber,
SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) as profit
from orders o join orderdetails od
on o.orderNumber =od.orderNumber
join products p on od.productCode =p.productCode
group by o.customerNumber
)
select c.contactLastName||' '||c.contactFirstName as Name, c.city, c.country,cte.profit
from customers c join cte
on c.customerNumber=cte.customerNumber
order by profit desc limit 5
---------------------------------------------------------------------------
Q4.Write a query to find the least 5 customers
Ans:
with cte as(
select o.customerNumber,
SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) as profit
from orders o join orderdetails od
on o.orderNumber =od.orderNumber
join products p on od.productCode =p.productCode
group by o.customerNumber
)
select c.contactLastName||' '||c.contactFirstName as Name, c.city, c.country,cte.profit
from customers c join cte
on c.customerNumber=cte.customerNumber
order by profit asc limit 5
---------------------------------------------------------------------------------
Q5 find the number of new customers arriving each month.
Ans:

WITH 
payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(DISTINCT customerNumber) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;

---------------------------------------------------------------------------------------
Q6: How Much Can We Spend on Acquiring New Customers
Ans:

with customer_profit as(
select o.customerNumber,
SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) as profit
from orders o join orderdetails od
on o.orderNumber =od.orderNumber
join products p on od.productCode =p.productCode
group by o.customerNumber
)
select avg(profit) as avg_customer_profit
from  customer_profit



