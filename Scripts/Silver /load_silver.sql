/*
==================================================
DML Script: Load Silver Table from Bronze
==================================================

Script Purpose:
This script truncates and loads the `silver.blink_supermarket_info_clean` table
by extracting, transforming, and cleansing data from the `bronze.blink_supermarket_info` table.

Actions:
- Truncate existing silver table
- Transform and insert cleaned data
*/

-- Truncate target silver table
PRINT 'Truncating table: silver.blink_supermarket_info_clean';
TRUNCATE TABLE silver.blink_supermarket_info_clean;

-- Insert cleaned data
PRINT 'Inserting cleaned data into: silver.blink_supermarket_info_clean';

INSERT INTO silver.blink_supermarket_info_clean (
    Item_Fat_Content,
    Item_Identifier,
    Item_Type,
    Outlet_Establishment_Year,
    Outlet_Identifier,
    Outlet_Location_Type,
    Outlet_Size,
    Outlet_Type,
    Item_Visibility,
    Item_Weight,
    Sales,
    Rating
)
SELECT
    -- Normalize fat content
    CASE 
        WHEN LOWER(LTRIM(RTRIM(b.Item_Fat_Content))) IN ('low fat', 'lf') THEN 'Low Fat'
        WHEN LOWER(LTRIM(RTRIM(b.Item_Fat_Content))) IN ('regular', 'reg') THEN 'Regular'
        ELSE 'Other'
    END AS Item_Fat_Content,

    LTRIM(RTRIM(b.Item_Identifier)) AS Item_Identifier,
    LTRIM(RTRIM(b.Item_Type)) AS Item_Type,
    b.Outlet_Establishment_Year,
    LTRIM(RTRIM(b.Outlet_Identifier)) AS Outlet_Identifier,
    LTRIM(RTRIM(b.Outlet_Location_Type)) AS Outlet_Location_Type,
    LTRIM(RTRIM(b.Outlet_Size)) AS Outlet_Size,
    LTRIM(RTRIM(b.Outlet_Type)) AS Outlet_Type,

    -- Set 0 visibility to NULL
    CASE 
        WHEN b.Item_Visibility = 0 THEN NULL
        ELSE b.Item_Visibility
    END AS Item_Visibility,

    -- Fill missing weight using avg per item type
    COALESCE(b.Item_Weight, avg_w.Avg_Weight) AS Item_Weight,

    b.Sales,
    b.Rating
FROM bronze.blink_supermarket_info b
LEFT JOIN (
    SELECT Item_Type, AVG(Item_Weight) AS Avg_Weight
    FROM bronze.blink_supermarket_info
    WHERE Item_Weight IS NOT NULL
    GROUP BY Item_Type
) AS avg_w
    ON b.Item_Type = avg_w.Item_Type;
GO
