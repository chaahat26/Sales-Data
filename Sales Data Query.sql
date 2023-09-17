--Inspecting Data
Select *
from [Sales Data]..sales_data

--Checking unique values
Select distinct status from [Sales Data]..sales_data
Select distinct year_id from [Sales Data]..sales_data
Select distinct productline from [Sales Data]..sales_data
Select distinct country from [Sales Data]..sales_data
Select distinct dealsize from [Sales Data]..sales_data
Select distinct territory from [Sales Data]..sales_data

--Grouping sales by product line
select productline, round(sum(sales),2) revenue
from [Sales Data]..sales_data
group by productline
order by 2 desc;

--Year in which most revenue was generated
select year_id, round(sum(sales),2) revenue
from [Sales Data]..sales_data
group by year_id
order by 2 desc;

--number of months they operated in 2005
Select distinct month_id 
from [Sales Data]..sales_data
where year_id = 2005;

--Which dealsize made the most revenue
select dealsize, round(sum(sales),2) revenue
from [Sales Data]..sales_data
group by dealsize
order by 2 desc;

--What was the best month for sales in a specific year?How much was earned that month?
select month_id, round(sum(sales),2) revenue, count(ordernumber) frequency
from [Sales Data]..sales_data
where year_id = 2003
group by month_id
order by 2 desc;

--which cars were most sold in the month of november?
select month_id,productline, round(sum(sales),2) revenue, count(ordernumber) frequency
from [Sales Data]..sales_data
where year_id = 2003 and month_id = 11
group by month_id,productline
order by 3 desc;

/* RFM ANANLYSIS(recency-frequency-monetary value) */
--Who is our best customer?
DROP TABLE IF EXISTS #rfm
;with rfm as
(
select customername,
       sum(sales) Monetary_value,
	   avg(sales) Avg_Monetary_value,
	   count(ordernumber) Frequency,
	   max(orderdate) last_order_date,
	   (select max(orderdate) from [Sales Data]..sales_data) max_order_date,
	   DATEDIFF(dd,max(orderdate),(select max(orderdate) from [Sales Data]..sales_data)) recency
from [Sales Data]..sales_data
group by customername 
),
rfm_calc as
(
	select r.*,
	ntile(4) over (order by recency desc) rfm_recency,
	ntile(4) over (order by frequency) rfm_frequency,
	ntile(4) over (order by Avg_Monetary_value) rfm_monetary
  from rfm r
)
select c.*,rfm_recency+rfm_frequency+rfm_monetary rfm_cell,
 cast(rfm_recency AS varchar)+cast(rfm_frequency AS varchar)+ cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_monetary,
	case 
		when rfm_cell_string in (111,112,121,122,123,132,131,211,212,114,141) then 'lost customers'
		when rfm_cell_string in (133,134,143,244,334,344) then 'slipping away,cannot lose'
		when rfm_cell_string in (311,411,331,421) then 'new customer'
		when rfm_cell_string in (222,223,233,322) then 'potential churners'
		when rfm_cell_string in (323,333,321,422,332,432) then 'active'
		when rfm_cell_string in (433,434,443,444) then 'loyal'
		end rfm_segment
from #rfm

--What products are most often sold together?
select distinct ordernumber, stuff(
			(select ','+ productcode
		from [Sales Data]..sales_data p
		where ordernumber in	
				   (select ordernumber 
					from
						(select ordernumber, count(*) rn
						from [Sales Data]..sales_data
						where STATUS = 'shipped'
						group by ORDERNUMBER
						) m
					where rn = 2 ) --change this number to change no of products
					and p.ordernumber = s.ordernumber
			for xml path ('')) 
			  ,1,1,'')Productcodes
  from [Sales Data]..sales_data s 
  order by 2 desc
/* from s.no 11 - 12 and 15 - 16 we can see which 2 products were mostly sold together*/ 
