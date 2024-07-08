# Consumer Goods Ad-hoc_Insights 
# Q1 Provide the list of markets in which customer "Atliq Exclusive" operated its business in the APAC region.
SELECT 
	 distinct market 
FROM dim_Customer 
WHERE 
	customer = "Atliq Exclusive" and 
    region = "APAC";
    
# Q2  What is percentage of unique product increase in 2021 vs 2020 ? the final output should contain these fields
# -- unique_products2020, unique_products_2021, percentage_chg
with ProductCounts2020 as (
SELECT
	count(distinct product_code) as unique_products_2020
FROM
	fact_sales_monthly 
WHERE fiscal_year = 2020
), 
ProductCounts2021 as (
SELECT 
	count(distinct product_code) as unique_products_2021
FROM 
	fact_sales_monthly WHERE fiscal_year = 2021
)
SELECT 
		unique_products_2020, 
	    unique_products_2021,
        round(((unique_products_2021-unique_products_2020)/unique_products_2020)*100,2) as percentage_change
FROM  ProductCounts2020, ProductCounts2021;

# Q3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains segments, product_counts
SELECT  segment,count(distinct product_code) as product_counts
FROM dim_product
GROUP BY segment
ORDER BY product_counts DESC;

#Q4 which segment had the most increase in unique products in 2021 vs 2020 ? The output contains these fields, segment, product_counts_2020, product_counts_2021, difference.
 with product_count_2021 as (
select 
	segment,
    count(distinct s.product_code) as product_count_2021
from dim_product p
join fact_sales_monthly s
on p.product_code = s.product_code 
where fiscal_year = 2021
group by 1
),
product_count_2020 as ( 
select 
	segment, 
    count(distinct s.product_code) as product_count_2020
from dim_product p 
join fact_sales_monthly s
on  p.product_code= s.product_code
where fiscal_year = 2020
group by 1)

select 
	p21.segment, product_count_2021, 
	product_count_2020 , 
	(product_count_2021 - product_count_2020) as difference 
from 
	product_count_2021 p21
join 
	product_count_2020 p20
on 
	p21.segment = p20.segment;

#Q5 Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code, product, manufacturing_cost.
 select 
	mc.product_code, product, 
	manufacturing_cost 
from fact_manufacturing_cost mc
join dim_product p
on p.product_code = mc.product_code
where 
	manufacturing_cost in (
		(select min(manufacturing_cost) from fact_manufacturing_cost),
        ( select max(manufacturing_cost) from fact_manufacturing_cost));
 
# Q6 generate a report which contains the top 5 customers who recieved a average high pre_invoice_discount_pct for the fiscal_year_2021 and in the indian market. The final output contains these fields, customer_code, customer, average_discount_percentage.
select 
	pi.customer_code, c.customer, 
    pi.pre_invoice_discount_pct 
from dim_customer c
join fact_pre_invoice_deductions pi
on  c.customer_code = pi.customer_code
where  fiscal_year = 2021 and 
		market = "india" and 
        pre_invoice_discount_pct > (
				select avg(pre_invoice_discount_pct) 
                from fact_pre_invoice_deductions )
order by pre_invoice_discount_pct desc
limit 5 ;

# Q7 Get the complete report of the gross sales amount for the customer "Atliq Exclusive" for each month. This analysis helps to get an idea of low and high performing months and take strategic decisions. The final report contains these outputs, Month , Year, Gross sales Amount
select monthname(date) as Months, gp.fiscal_year as year, round(sum(gross_price * sold_quantity),2) as Gross_sales_amount from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price gp
on s.product_code = gp.product_code 
where customer = "Atliq Exclusive"
group by 2,1
order by 3 desc;

# Q8 In which Quarter of 2020, got the maximum total_sold_quantity ?
select
	  concat("Q",ceil(month(date_add(date, interval 4 month))/3)) as Quarter,sum(sold_quantity) as total_sold_qty
from fact_sales_monthly
where fiscal_year= "2020"
group by 1
order by total_sold_qty desc
limit  1;

# Q9 which channel helped to bring more gross sales in the year fiscal year 2021 and the percentage of contribution ? The output contains and these fields, channel, gross_sales_mln, percentage.
with sales as (
	select   c.channel, round((sum(gp.gross_price*s.sold_quantity)/1000000),2) as total_gross_sales 
	from fact_gross_price gp
	join fact_sales_monthly s
	on s.fiscal_year = gp.fiscal_year and s.product_code = gp.product_code
	join dim_customer c
	on c.customer_code = s.customer_code
	where s.fiscal_year = 2021
    group by channel
 )
 select channel, total_gross_sales, (total_gross_sales *100 /sum(total_gross_sales) over() )  as percentage  from sales;
 
# Q10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields division,product_code, total_sold_qty, rank_order
with top_products as (
select division, p.product_code, product, sum(sold_quantity ) as total_sold_qty from dim_product p 
join fact_sales_monthly s 
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by 1,2,3
), all_rank as (
	select *, dense_rank() over(partition by division order by total_sold_qty desc) as rank_order from top_products
)
select * from all_rank