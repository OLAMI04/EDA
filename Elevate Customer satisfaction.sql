CREATE SCHEMA tech_electro;
USE tech_electro;

---- DATA EXPLORATION
Select * From external_factors;
select * from product_information;
Select * from sales_data;

---- Understanding the struction of our dataset
Describe external_factors;
Describe product_information;
Describe sales_data;

---- DATA CLEANING
--- CHANGING TO THE RIGHT DATA TYPE
ALTER TABLE external_factors
ADD COLUMN New_Sales_Date DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE external_factors
SET New_Sales_Date = STR_TO_DATE(Sales_Date, '%d/%m/%y');
ALTER TABLE external_factors
Drop Column New_Sales_Date;
UPDATE external_factors
SET Sales_Date = STR_TO_DATE(Sales_Date, '%d/%m/%Y');

ALTER TABLE external_factors
Modify Column GDP DECIMAL(15, 2);

ALTER TABLE external_factors
Modify Column 	Inflation_Rate DECIMAL(15, 2);

ALTER TABLE external_factors
Modify Column Seasonal_Factor DECIMAL(5, 2);

SHOW COLUMNS FROM external_factors;

---- Product
ALter Table product_information
Modify Column Promotions ENUM('yes', 'no');
UPDATE product_information
SET Promotions = CASE
WHEN Promotions = 'yes' THEN 'yes'
WHEN Promotions = 'no' THEN 'no'
ELSE NULL
END; 
 
 Select  * FROM product_information;
Describe product_information;

ALTER TABLE sales_data
ADD COLUMN New_Sales_Date DATE;
UPDATE sales_data
SET New_Sales_Date = STR_TO_DATE(Sales_Date, '%d/%m/%y');
ALTER TABLE sales_data
Drop Column Sales_Date;


Select * from sales_data;
desc sales_data;

ALTER TABLE sales_data
ADD COLUMN Temp_Sales_Date DATE NULL DEFAULT NULL;
UPDATE sales_data
SET Temp_Sales_Date = STR_TO_DATE(SalesDate, '%d/%m/%Y');
SELECT SalesDate, Temp_Sales_Date FROM sales_data LIMIT 15;
ALTER TABLE sales_data
DROP COLUMN SalesDate;
ALTER TABLE sales_data
CHANGE COLUMN Temp_Sales_Date Sales_Date DATE NULL DEFAULT NULL;

SELECT
	Sum(CASE WHEN Sales_Date IS NULL THEN 1 ELSE 0 END) AS missing_Sales_Dates,
    Sum(CASE WHEN GDP IS NULL THEN 1 ELSE 0 END) AS missing_GDP,
    Sum( CASE WHEN Inflation_Rate IS NULL THEN 1 ELSE 0 END) AS miising_inflation_rate,
    Sum(CASE WHEN Seasonal_Factor IS NULL THEN 1 ELSE 0 END) AS missing_seasonal_Factor
    FROM external_factors;
    
  ----- Production_information  
SELECT
	Sum(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS missing_product_ID,
    Sum(CASE WHEN Product_Category IS NULL THEN 1 ELSE 0 END) AS missing_product_category,
    Sum( CASE WHEN Promotions IS NULL THEN 1 ELSE 0 END) AS miising_promotions
    FROM product_information;
--- Sales_Data
SELECT
	Sum(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS missing_product_ID,
    Sum(CASE WHEN Inventory_Quantity IS NULL THEN 1 ELSE 0 END) AS missing_inventory_quantity,
    Sum(CASE WHEN Product_Cost IS NULL THEN 1 ELSE 0 END) AS miising_product_cost,
    Sum(CASE WHEN Sales_Date IS NULL THEN 1 ELSE 0 END) AS missing_sales_date
    FROM sales_data;
    
    ---- Check for duplicate
    ------ From external_factors
    Select 
    Sales_Date, 
    Count(*) AS Count
    From external_factors
    Group By Sales_Date
    Having count >1;

Select count(*) 
from 
(Select Sales_Date, Count(*) AS Count
    From external_factors
    Group By Sales_Date
    Having count >1) AS dup;


--- Check for duplicate
    ------ From sales_data
    Select 
    Product_ID, 
    Count(*) AS Count
    From sales_data
    Group By Product_ID
    Having count >1;
    
    Select count(*) from 
    (Select Product_ID, Count(*) AS Count
    From sales_data
    Group By Product_ID
    Having count >1) AS dup;
    
     ------ From Product_Information
    Select 
    Product_id, Product_Category, 
    Count(*) AS Count
    From product_information
    Group By Product_id, Product_Category
    Having count >1;
    
    Select count(*) from (Select 
    Product_id,
    Count(*) AS Count
    From product_information
    Group By Product_id
    Having count >1) AS dup;

------ From Sales_data
    Select 
    Product_id, Sales_Date, 
    Count(*) AS Count
    From sales_data
    Group By Product_id, Sales_Date
	Having count >1;

---- Deaing with duplicate from external_factord and product_information
--- External_factor
Delete e1 from external_factors e1
inner join (
select Sales_Date,
row_number () Over (partition by Sales_Date order by Sales_Date) rn
From
external_factors) e2 On e1.Sales_Date = e2.Sales_Date
Where e2.rn > 1;

----- Product_information
Delete p1 from product_information p1
inner join(
Select Product_ID, 
row_number () over (partition by Product_ID order by Product_ID) rn
From
product_information) p2 on p1.Product_ID = p2.Product_ID
Where p2.rn > 1;

---- DATA INTREGRATION
---- sales_data and product_information
CREATE VIEW sales_data_product_information AS
Select
s.Product_ID,
s.Inventory_Quantity,
s.Product_Cost,
s.Sales_Date,
p.Product_Category,
p.Promotions
From
sales_data s
Join
product_information p
on
s.Product_ID = p.Product_ID;

----- sales_data_product_information and External_data
CREATE VIEW Inventory_data AS
Select
sp.Product_ID,
sp.Inventory_Quantity,
sp.Product_Cost,
sp.Sales_Date,
sp.Product_Category,
sp.Promotions,
e.GDP,
e.Inflation_Rate,
e.Seasonal_Factor
From
sales_data_product_information sp
LEFT JOIN external_factors e
on
sp.Sales_Date = e.Sales_Date


----- DESRIPTIVE ANALYSIS
--- BASICS STATISTICS
-- Average sales( calculated as products of "inventory_Quantity" and "Product_Cost")
Select
Product_ID,
Avg(Inventory_Quantity * Product_Cost) Avg_Sales
From
sales_data
Group By Product_ID
Order by Avg_Sales DESC

----- Medium stock level
SELECT Product_ID, AVG(Inventory_Quantity) AS Medium_stock
FROM (
    SELECT 
        Product_ID,
        Inventory_Quantity,
        ROW_NUMBER() OVER (PARTITION BY Product_ID ORDER BY Inventory_Quantity ASC) AS row_num_asc,
        ROW_NUMBER() OVER (PARTITION BY Product_ID ORDER BY Inventory_Quantity DESC) AS row_num_desc
    FROM sales_data
) subquery
WHERE row_num_asc = row_num_desc -- This condition selects the median value
GROUP BY Product_ID;

---- Product Performance metrics (total sales per product)
SELECT 
Product_ID,
Round(Sum(Inventory_Quantity * Product_Cost)) total_sales
From
sales_data
Group by Product_ID
Order by total_sales DESC;

---- Identify high demands products base on average sales
SELECT Product_ID, AVG(Inventory_Quantity) AS avg_sales
FROM sales_data
GROUP BY Product_ID
HAVING AVG(Inventory_Quantity) > (
    SELECT AVG(Inventory_Quantity) * 0.95 
    FROM sales_data
);

----- Calculate stockout frequency for high demand products
Select 
s.Product_ID,
Count(*) as stockout_Frequency
From sales_data s
Where s.Product_ID IN (Select Product_ID FROM sales_data)
AND s.Inventory_Quantity = 0
GROUP BY s.Product_ID;

---- INFLUENCE OF EXTERNAL DATA
---- GDP
SELECT 
    Product_ID,
    AVG(CASE WHEN `GDP` > 0 THEN Inventory_Quantity ELSE NULL END) AS avg_sales_positives_gdp,
    AVG(CASE WHEN `GDP` <= 0 THEN Inventory_Quantity ELSE NULL END) AS avg_sales_non_positives_gdp
FROM 
    sales_data s
    join external_factors e
    on 
    s.Sales_Date = e.Sales_Date
GROUP BY  
    Product_ID
HAVING 
    AVG(CASE WHEN `GDP` > 0 THEN Inventory_Quantity ELSE NULL END) IS NOT NULL;

---- INFLATION
SELECT 
    Product_ID,
    AVG(CASE WHEN Inflation_Rate > 0 THEN Inventory_Quantity ELSE NULL END) AS avg_sales_positives_inflation,
    AVG(CASE WHEN Inflation_Rate <= 0 THEN Inventory_Quantity ELSE NULL END) AS avg_sales_non_positives_inflation
FROM 
    sales_data s
    join external_factors e
    on 
    s.Sales_Date = e.Sales_Date
GROUP BY  
    Product_ID
HAVING 
    AVG(CASE WHEN Inflation_Rate > 0 THEN Inventory_Quantity ELSE NULL END) IS NOT NULL;
    
----- Optimizing Inventory
----- Determine the optimal reorder points for each product base on historical sales data and external factors
----- Reorder point = lead time Demands + Safety Stock
With InventoryCalculations AS (
	SElECT Product_ID,
    AVG(rolling_avg_sales) AS rolling_avg_sales,
    AVG(rolling_avg_variance) AS rolling_avg_variance
From (
SElECT Product_ID,
AVG(daily_sales) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_sales,
AVG(Squared_diff) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_variance  
From (
SElECT Product_ID,
 Sales_Date, Inventory_Quantity * Product_Cost As daily_sales,
 (Inventory_Quantity * Product_Cost - AVG(Inventory_Quantity * Product_Cost) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW))
*(Inventory_Quantity * Product_Cost - AVG(Inventory_Quantity * Product_Cost) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as Squared_diff
 From inventory_data
 ) subquery
  ) subquery2
 Group by Product_ID
)
 Select Product_ID,
 rolling_avg_sales * 7 as lead_time_demands,
 1.645 * (rolling_avg_variance* 7) as safety_stock,
 (rolling_avg_variance * 7) + (1.645 * (rolling_avg_variance * 7)) as reorder_point
 From InventoryCalculations;
 
 ----- Create Inventory Optimization Table
 Create Table inventory_optimization (
	Product_ID INT,
    Reorder_point DOUBLE
    );
    
    ----- step 2-- create the stored procedure to recalculate Reorder Point
    DELIMITER \\
    CREATE PROCEDURE RecalculateReorderPoint(ProductID INT)
    BEGIN
		DECLARE avgrollingScales DOUBLE;
		DECLARE avgrollingVariance DOUBLE;
		DECLARE leadTimeDemand DOUBLE;
		DECLARE safetyStock DOUBLE;
        DECLARE reorderPoint DOUBLE;
        
    SElECT AVG(rolling_avg_sales), AVG(rolling_avg_variance)
    INTO rollingavgsales, rollingavgvariance
From (
SElECT Product_ID,
AVG(daily_sales) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_sales,
AVG(Squared_diff) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_variance  
From (
SElECT Product_ID,
 Sales_Date, Inventory_Quantity * Product_Cost As daily_sales,
 (Inventory_Quantity * Product_Cost - AVG(Inventory_Quantity * Product_Cost) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW))
*(Inventory_Quantity * Product_Cost - AVG(Inventory_Quantity * Product_Cost) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as Squared_diff
 From inventory_data
 ) innerDerived
  ) outterDerived;
 Set leadTimeDemand = avgRollingSales * 7;
 Set safetyStock = 1.645 * SQRT(avgrollingvariance * 7 );
 Set reorderpoint = leadTimeDemand + safetyStock;
 
     INSERT INTO inventory_optimization (Product_ID, Reorder_Point)
	  VALUES (ProductID, ReorderPoint)
ON DUPLICATE KEY UPDATE Reorder_Point = ReorderPoint;
END 
DELIMITER //;
    
-- Steps 3: Make inventory_data a permanent table
CREATE TABLE inventory_table AS SELECT * From inventory_data
-- Steps 4: Create the Trigger
DELIMITER \\
CREATE TRIGGER AfterinsertunifieldTable
AFTER INSERT ON inventory_table
For each row
BEGIN
   CALL RecalculateReorderPoint(New.Product_ID);
END //
DELIMITER ;

-- Overstocking and Understocking
With Rollingsales AS (
Select Product_ID,
Sales_Date,
 AVG(Inventory_Quantity * Product_Cost) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) As rolling_avg_sales    
 From
 Inventory_table
 ), 
 -- Calculate the number of days a product was out of stock
 Stockoutdays AS (
 Select Product_ID, 
 Count(*) As stockout_days
 From inventory_table
 Where Inventory_Quantity = 0
 Group by Product_ID
 )
 -- Join the above CTEs with the main table to get the results
 Select f.Product_ID,
 AVG(f.Inventory_Quantity * f.Product_Cost) as avg_inventory_value,
 AVG(rs.rolling_avg_sales) as avg_rolling_sales,
 COALESCE(sd.stockout_days, 0) as stockout_days
 from inventory_table f
 Join rollingsales rs on f.Product_ID = rs.Product_ID AND f.Sales_Date = rs.Sales_Date
 Left join StockoutDays sd on f.Product_ID = sd.Product_ID
 Group By f.Product_ID, sd.Stockout_days;
 
 -- Monitor And Adjust
 -- Monitor Inventory levels
	DELIMITER //
CREATE PROCEDURE MonitorSalesTrends()
BEGIN
Select Product_ID, AVG(Inventory_Quantity) avginventory
From inventory_table
Group by Product_ID
Order by avginventory DESC;
END
DELIMITER \\

-- Monitor Sales Trend
DELIMITER \\
create procedure MonitorSalesTrend()
BEGIN
Select Product_ID, Sales_Date
AVG(Inventory_Quantity * Product_Cost) OVER (PARTITION BY Product_ID ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) As rolling_avg_sales    
 From
 Inventory_table
 Order By  Product_ID, Sales_Date;
END
DELIMITER \\;

-- Monitor storeout Frequency
DELIMITER //
CREATE PROCEDURE Monitorstockout(),
BEGIN
Select Product_ID, Count(*) AS StockoutDays
From inventory_table
Where Inventory_Quantity = 0
group by Product_ID
Order by StockoutDays desc,
END\\
DELIMITER ;



 
 
 
 
 
 
 
 
 
    
    
    
    
    
    
    
    

