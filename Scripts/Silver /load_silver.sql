/*
==================================================
Stored Procedure: Load Blink Supermarket Data to Silver
==================================================

Purpose:
- Truncate and load cleaned data from bronze.blink_supermarket_info 
  into silver.blink_supermarket_info_clean.

Actions Performed:
- Normalize fat content
- Trim all text fields
- Replace zero visibility with NULL
- Fill missing weights using average weight per Item_Type
- Add error handling and logging

Usage:
  EXEC silver.load_blink_supermarket_info;
*/

CREATE OR ALTER PROCEDURE silver.load_blink_supermarket_info AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '****************************************';
        PRINT '   STARTING SILVER LOAD FOR BLINKIT     ';
        PRINT '****************************************';

        -- Step 1: Truncate target table
        SET @start_time = GETDATE();
        PRINT 'Truncating table: silver.blink_supermarket_info_clean';
        TRUNCATE TABLE silver.blink_supermarket_info_clean;

        -- Step 2: Insert cleaned data into silver
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
            -- Standardize fat content values
            CASE 
                WHEN LOWER(LTRIM(RTRIM(b.Item_Fat_Content))) IN ('low fat', 'lf') THEN 'Low Fat'
                WHEN LOWER(LTRIM(RTRIM(b.Item_Fat_Content))) IN ('regular', 'reg') THEN 'Regular'
                ELSE 'Other'
            END AS Item_Fat_Content,

            -- Trim text fields
            LTRIM(RTRIM(b.Item_Identifier)) AS Item_Identifier,
            LTRIM(RTRIM(b.Item_Type)) AS Item_Type,
            b.Outlet_Establishment_Year,
            LTRIM(RTRIM(b.Outlet_Identifier)) AS Outlet_Identifier,
            LTRIM(RTRIM(b.Outlet_Location_Type)) AS Outlet_Location_Type,
            LTRIM(RTRIM(b.Outlet_Size)) AS Outlet_Size,
            LTRIM(RTRIM(b.Outlet_Type)) AS Outlet_Type,

            -- Replace 0 with NULL in visibility
            CASE 
                WHEN b.Item_Visibility = 0 THEN NULL
                ELSE b.Item_Visibility
            END AS Item_Visibility,

            -- Fill null weights with average per Item_Type
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

        -- Step 3: Log load duration
        SET @end_time = GETDATE();
        PRINT '>> Load Duration (silver.blink_supermarket_info_clean): ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT 'TOTAL BATCH DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) + ' seconds';

    END TRY
    BEGIN CATCH
        PRINT '*** ERROR LOADING SILVER BLINKIT DATA ***';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT 'Error Message: ' + ERROR_MESSAGE();

        SET @batch_end_time = GETDATE();
        PRINT 'TOTAL BATCH DURATION (FAILED): ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) + ' seconds';

        THROW;  -- re-raise the error
    END CATCH
END
GO


