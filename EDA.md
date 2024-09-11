````sql
CREATE SCHEMA tech_electro;
````

````sql
USE tech_electro;
````

#### DATA EXPLORATION
````sql
Select * From external_factors;
````
![image](https://github.com/user-attachments/assets/f52a27bb-c7fe-4fd3-bc06-f14155b03c7c)


````sql
select * from product_information;
````
![image](https://github.com/user-attachments/assets/42a88c84-234b-42fa-883f-1729ebb94224)


````sql
Select * from sales_data;
````
![image](https://github.com/user-attachments/assets/eb14a4cd-5873-4372-b86d-74e291665953)


#### UNDERSTANDING DATA SET STRUCTURE
````sql
Describe external_factors;
````
![image](https://github.com/user-attachments/assets/83c9ca82-1df5-41b0-a5c5-cbba903a1cc0)

````sql
Describe product_information;
````
![image](https://github.com/user-attachments/assets/d9788751-e222-4045-af38-7599b51ea5e8)

```sql
Describe sales_data;
````
![image](https://github.com/user-attachments/assets/929dddf9-d564-4d83-87ff-afe155e8dff7)

#### DATA INTREGRATION
### sales_data and product_information
### create view sales_data_product_information AS
````sql
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
````
![image](https://github.com/user-attachments/assets/6e5c1fa2-c23d-4e70-b15f-e5ddc2a9b78a)

#### sales_data_product_information and External_data
### create view Inventory_data AS
````sql
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
````
![image](https://github.com/user-attachments/assets/cbc7a9fc-d1b6-4441-925c-ab60416411f4)

#### DESRIPTIVE ANALYSIS
#### BASICS STATISTICS
### average sales( calculated as products of "inventory_Quantity" and "Product_Cost")
````sql
Select
Product_ID,
Avg(Inventory_Quantity * Product_Cost) Avg_Sales
From
sales_data
Group By Product_ID
Order by Avg_Sales DESC
````
![image](https://github.com/user-attachments/assets/1a5ea875-0654-4b59-8006-09195294c423)

#### Medium stock level
````sql
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
````
![image](https://github.com/user-attachments/assets/fcd07ee7-99d0-46ec-9f5d-8a753919f889)

#### Product Performance metrics (total sales per product)
````sql
SELECT 
Product_ID,
Round(Sum(Inventory_Quantity * Product_Cost)) total_sales
From
sales_data
Group by Product_ID
Order by total_sales DESC;
````
![image](https://github.com/user-attachments/assets/232c3d98-4a5b-4d82-98bc-27ae788dd71a)

#### Identify high demands products base on average sales
````sql
SELECT Product_ID, AVG(Inventory_Quantity) AS avg_sales
FROM sales_data
GROUP BY Product_ID
HAVING AVG(Inventory_Quantity) > (
    SELECT AVG(Inventory_Quantity) * 0.95 
    FROM sales_data
);
````
![image](https://github.com/user-attachments/assets/d840befc-9632-49cc-be42-b0c1b7ed1961)




































