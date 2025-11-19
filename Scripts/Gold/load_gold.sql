/*
==================================================
Stored Procedure: Load Blinkit Gold Layer
==================================================

Purpose:
Aggregate KPIs from silver.blink_supermarket_info_clean into 
gold.blink_sales_summary.

KPIs:
- Total Sales
- Average Sales
- Number of Items
- Average Rating

Usage:
  EXEC gold.load_blink_sales_summary;
*/

CREATE OR ALTER PROCEDURE gold.load_blink_sales_summary AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '****************************************';
        PRINT '     STARTING GOLD LAYER LOAD           ';
        PRINT '****************************************';

        -- Step 1: Truncate gold table
        SET @start_time = GETDATE();
        PRINT 'Truncating table: gold.blink_sales_summary';
        TRUNCATE TABLE gold.blink_sales_summary;

        -- Step 2: Insert aggregated KPIs
        PRINT '>> Inserting aggregated data into: gold.blink_sales_summary';

        INSERT INTO gold.blink_sales_summary (
            Item_Fat_Content,
            Item_Type,
            Outlet_Identifier,
            Outlet_Location_Type,
            Outlet_Size,
            Outlet_Type,
            Outlet_Establishment_Year,
            Number_of_Items,
            Total_Sales,
            Average_Sales,
            Average_Rating
        )
        SELECT 
            Item_Fat_Content,
            Item_Type,
            Outlet_Identifier,
            Outlet_Location_Type,
            Outlet_Size,
            Outlet_Type,
            Outlet_Establishment_Year,

            COUNT(DISTINCT Item_Identifier) AS Number_of_Items,
            SUM(Sales) AS Total_Sales,
            AVG(Sales) AS Average_Sales,
            AVG(Rating) AS Average_Rating

        FROM silver.blink_supermarket_info_clean
        GROUP BY 
            Item_Fat_Content,
            Item_Type,
            Outlet_Identifier,
            Outlet_Location_Type,
            Outlet_Size,
            Outlet_Type,
            Outlet_Establishment_Year;

        -- Step 3: Log duration
        SET @end_time = GETDATE();
        PRINT '>> Load Duration (gold.blink_sales_summary): ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT 'TOTAL BATCH DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) + ' seconds';

    END TRY
    BEGIN CATCH
        PRINT '*** ERROR LOADING GOLD LAYER ***';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT 'Error Message: ' + ERROR_MESSAGE();

        SET @batch_end_time = GETDATE();
        PRINT 'TOTAL BATCH DURATION (FAILED): ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) + ' seconds';

        THROW;
    END CATCH
END
GO
