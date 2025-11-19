/* 
==================================================
DDL Script: Create Silver Tables
==================================================

Script Purpose:
This script creates tables in the 'silver' schema, dropping existing tables
if they already exist.
Run this script to re-define the DDL structure of cleaned Blinkit data
*/

-- Create Tables

IF OBJECT_ID('silver.blink_supermarket_info_clean', 'U') IS NOT NULL
    DROP TABLE silver.blink_supermarket_info_clean;

CREATE TABLE silver.blink_supermarket_info_clean (
    Item_Fat_Content NVARCHAR(50),
    Item_Identifier NVARCHAR(50),
    Item_Type NVARCHAR(50),
    Outlet_Establishment_Year INT,
    Outlet_Identifier NVARCHAR(50),
    Outlet_Location_Type NVARCHAR(50),
    Outlet_Size NVARCHAR(50),
    Outlet_Type NVARCHAR(50),
    Item_Visibility FLOAT, 
    Item_Weight FLOAT,
    Sales FLOAT,
    Rating INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
