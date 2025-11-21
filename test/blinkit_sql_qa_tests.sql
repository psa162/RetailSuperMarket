/*
Blinkit – SQL QA Tests (Silver ↔ Gold)
Run in SQL Server.

1) Row-count vs distinct groups
*/
SELECT COUNT(*) AS silver_rows
FROM silver.blink_supermarket_info_clean;

SELECT COUNT(DISTINCT Item_Fat_Content, Item_Type, Outlet_Identifier,
             Outlet_Location_Type, Outlet_Size, Outlet_Type, Outlet_Establishment_Year) AS silver_distinct_groups
FROM silver.blink_supermarket_info_clean;

SELECT COUNT(*) AS gold_rows FROM gold.blink_sales_summary;

/*
2) KPI equality by group
*/
WITH silver_aggr AS (
  SELECT Item_Fat_Content, Item_Type, Outlet_Identifier,
         Outlet_Location_Type, Outlet_Size, Outlet_Type, Outlet_Establishment_Year,
         COUNT(DISTINCT Item_Identifier) AS Number_of_Items,
         SUM(Sales) AS Total_Sales,
         AVG(Sales) AS Average_Sales,
         AVG(Rating) AS Average_Rating
  FROM silver.blink_supermarket_info_clean
  GROUP BY Item_Fat_Content, Item_Type, Outlet_Identifier,
           Outlet_Location_Type, Outlet_Size, Outlet_Type, Outlet_Establishment_Year
)
SELECT g.*, s.Number_of_Items AS s_Number_of_Items, s.Total_Sales AS s_Total_Sales,
       s.Average_Sales AS s_Average_Sales, s.Average_Rating AS s_Average_Rating,
       (g.Total_Sales - s.Total_Sales) AS delta_total_sales,
       (g.Average_Sales - s.Average_Sales) AS delta_avg_sales,
       (g.Average_Rating - s.Average_Rating) AS delta_avg_rating
FROM gold.blink_sales_summary g
LEFT JOIN silver_aggr s ON s.Item_Fat_Content = g.Item_Fat_Content
  AND s.Item_Type = g.Item_Type
  AND s.Outlet_Identifier = g.Outlet_Identifier
  AND s.Outlet_Location_Type = g.Outlet_Location_Type
  AND s.Outlet_Size = g.Outlet_Size
  AND s.Outlet_Type = g.Outlet_Type
  AND s.Outlet_Establishment_Year = g.Outlet_Establishment_Year
WHERE (
    ABS(ISNULL(g.Total_Sales,0) - ISNULL(s.Total_Sales,0)) > 0.01 OR
    ABS(ISNULL(g.Average_Sales,0) - ISNULL(s.Average_Sales,0)) > 0.0001 OR
    ABS(ISNULL(g.Average_Rating,0) - ISNULL(s.Average_Rating,0)) > 0.0001 OR
    ISNULL(g.Number_of_Items, -1) <> ISNULL(s.Number_of_Items, -1)
);

/*
3) Coverage: missing or extra groups
*/
WITH silver_keys AS (
  SELECT DISTINCT Item_Fat_Content, Item_Type, Outlet_Identifier,
         Outlet_Location_Type, Outlet_Size, Outlet_Type, Outlet_Establishment_Year
  FROM silver.blink_supermarket_info_clean
)
SELECT 'missing_in_gold' AS issue, sk.*
FROM silver_keys sk
LEFT JOIN gold.blink_sales_summary g ON g.Item_Fat_Content = sk.Item_Fat_Content
  AND g.Item_Type = sk.Item_Type
  AND g.Outlet_Identifier = sk.Outlet_Identifier
  AND g.Outlet_Location_Type = sk.Outlet_Location_Type
  AND g.Outlet_Size = sk.Outlet_Size
  AND g.Outlet_Type = sk.Outlet_Type
  AND g.Outlet_Establishment_Year = sk.Outlet_Establishment_Year
WHERE g.Outlet_Identifier IS NULL
UNION ALL
SELECT 'extra_in_gold' AS issue, g.Item_Fat_Content, g.Item_Type, g.Outlet_Identifier,
       g.Outlet_Location_Type, g.Outlet_Size, g.Outlet_Type, g.Outlet_Establishment_Year
FROM gold.blink_sales_summary g
LEFT JOIN silver_keys sk ON sk.Item_Fat_Content = g.Item_Fat_Content
  AND sk.Item_Type = g.Item_Type
  AND sk.Outlet_Identifier = g.Outlet_Identifier
  AND sk.Outlet_Location_Type = g.Outlet_Location_Type
  AND sk.Outlet_Size = g.Outlet_Size
  AND sk.Outlet_Type = g.Outlet_Type
  AND sk.Outlet_Establishment_Year = g.Outlet_Establishment_Year
WHERE sk.Item_Type IS NULL;

/*
4) Totals reconciliation (global)
*/
SELECT
  (SELECT SUM(Sales) FROM silver.blink_supermarket_info_clean) AS silver_total_sales,
  (SELECT SUM(Total_Sales) FROM gold.blink_sales_summary) AS gold_total_sales,
  (SELECT SUM(DISTINCT Number_of_Items) FROM gold.blink_sales_summary) AS gold_items_note,
  (SELECT AVG(Rating) FROM silver.blink_supermarket_info_clean) AS silver_avg_rating;

/*
5) Spot-check largest groups
*/
SELECT TOP 10
  Item_Type, Outlet_Type, Outlet_Size, Outlet_Location_Type,
  COUNT(*) AS silver_rows, SUM(Sales) AS silver_sales
FROM silver.blink_supermarket_info_clean
GROUP BY Item_Type, Outlet_Type, Outlet_Size, Outlet_Location_Type
ORDER BY silver_sales DESC;
