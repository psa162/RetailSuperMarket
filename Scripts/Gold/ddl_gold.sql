/*
==================================================
DDL Script: Create Gold Table for Blinkit KPIs
==================================================

Purpose:
Create a reporting-optimized gold layer table with aggregated KPIs
from the silver layer.

Table: gold.blink_sales_summary
*/

IF OBJECT_ID('gold.blink_sales_summary', 'U') IS NOT NULL
    DROP TABLE gold.blink_sales_summary;

CREATE TABLE gold.blink_sales_summary (
    Item_Fat_Content NVARCHAR(50),
    Item_Type NVARCHAR(50),
    Outlet_Identifier NVARCHAR(50),
    Outlet_Location_Type NVARCHAR(50),
    Outlet_Size NVARCHAR(50),
    Outlet_Type NVARCHAR(50),
    Outlet_Establishment_Year INT,
    
    Number_of_Items INT,
    Total_Sales FLOAT,
    Average_Sales FLOAT,
    Average_Rating FLOAT,
    
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
