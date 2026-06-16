	/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
-- SHOW VARIABLES LIKE 'secure_file_priv';

SET GLOBAL local_infile = 'ON';

USE bronze;

-- ===================================================
-- 1. 按下總流程的「啟動馬表」
-- ===================================================
SET @batch_start = NOW();

-- ===================================================
-- 2. 執行 6 張表的 TRUNCATE 與計時 LOAD DATA
-- ===================================================

-- 🕒 表 1：crm_cust_info
SET @start_time = NOW();
TRUNCATE TABLE crm_cust_info;
LOAD DATA LOCAL INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
INTO TABLE bronze.crm_cust_info FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SET @t1_duration = TIMESTAMPDIFF(SECOND, @start_time, NOW());


-- 🕒 表 2：crm_prd_info
SET @start_time = NOW();
TRUNCATE TABLE crm_prd_info;
LOAD DATA LOCAL INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
INTO TABLE bronze.crm_prd_info FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SET @t2_duration = TIMESTAMPDIFF(SECOND, @start_time, NOW());


-- 🕒 表 3：crm_sales_details
SET @start_time = NOW();
TRUNCATE TABLE crm_sales_details;
LOAD DATA LOCAL INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
INTO TABLE bronze.crm_sales_details FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SET @t3_duration = TIMESTAMPDIFF(SECOND, @start_time, NOW());


-- 🕒 表 4：erp_CUST_AZ12
SET @start_time = NOW();
TRUNCATE TABLE erp_CUST_AZ12;
LOAD DATA LOCAL INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_erp/cust_az12.csv'
INTO TABLE bronze.erp_CUST_AZ12 FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SET @t4_duration = TIMESTAMPDIFF(SECOND, @start_time, NOW());


-- 🕒 表 5：erp_LOC_A101
SET @start_time = NOW();
TRUNCATE TABLE erp_LOC_A101;
LOAD DATA LOCAL INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_erp/loc_a101.csv'
INTO TABLE bronze.erp_LOC_A101 FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SET @t5_duration = TIMESTAMPDIFF(SECOND, @start_time, NOW());


-- 🕒 表 6：erp_PX_CAT_G1V2
SET @start_time = NOW();
TRUNCATE TABLE erp_PX_CAT_G1V2;
LOAD DATA LOCAL INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_erp/px_cat_g1v2.csv'
INTO TABLE bronze.erp_PX_CAT_G1V2 FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SET @t6_duration = TIMESTAMPDIFF(SECOND, @start_time, NOW());


-- ===================================================
-- 3. 按下總流程的「結束馬表」
-- ===================================================
SET @batch_end = NOW();
SET @total_duration = TIMESTAMPDIFF(SECOND, @batch_start, @batch_end);


-- ===================================================
-- 4. 終極成果：只用一張表吐出所有計時與筆數統計！
-- ===================================================
SELECT 'crm_cust_info' AS `Table Name`, COUNT(*) AS `Row Count`, CONCAT(@t1_duration, ' sec') AS `Load Duration` FROM bronze.crm_cust_info
UNION ALL
SELECT 'crm_prd_info', COUNT(*), CONCAT(@t2_duration, ' sec') FROM bronze.crm_prd_info
UNION ALL
SELECT 'crm_sales_details', COUNT(*), CONCAT(@t3_duration, ' sec') FROM bronze.crm_sales_details
UNION ALL
SELECT 'erp_CUST_AZ12', COUNT(*), CONCAT(@t4_duration, ' sec') FROM bronze.erp_CUST_AZ12
UNION ALL
SELECT 'erp_LOC_A101', COUNT(*), CONCAT(@t5_duration, ' sec') FROM bronze.erp_LOC_A101
UNION ALL
SELECT 'erp_PX_CAT_G1V2', COUNT(*), CONCAT(@t6_duration, ' sec') FROM bronze.erp_PX_CAT_G1V2
UNION ALL
SELECT '=====================', '=========', '========='
UNION ALL
SELECT '>>> TOTAL BATCH PROCESSED', '---', CONCAT(@total_duration, ' seconds') ;

/* 以下這段沒辦法跑 因為mysql底層不讓procedure內有load data
USE bronze;
DELIMITER $$

CREATE PROCEDURE load_bronze()
BEGIN
	
    -- 1. 宣告時間與錯誤訊息變數
    DECLARE start_time DATETIME;
    DECLARE end_time DATETIME;
    DECLARE batch_start_time DATETIME;
    DECLARE batch_end_time DATETIME;
    
    -- 用於錯誤處理的變數
    DECLARE error_code CHAR(5) DEFAULT '00000';
    DECLARE error_msg TEXT;
    DECLARE error_sch TEXT;
    DECLARE error_tab TEXT;

    -- 2. 定義錯誤處理器（替代 BEGIN CATCH）
    -- 當發生任何 SQL 錯誤 (SQLEXCEPTION) 時會觸發此區塊
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 獲取最後發生的錯誤代碼與訊息
        GET DIAGNOSTICS CONDITION 1 
            error_code = RETURNED_SQLSTATE, error_msg = MESSAGE_TEXT, error_sch = SCHEMA_NAME, error_tab = TABLE_NAME;
            
        -- 【業界標準配備】：將錯誤自動寫入硬碟的日誌表
        INSERT INTO bronze.error_log (proc_name, sch_name, tab_name, error_code, error_message)
        VALUES ('load_bronze', error_sch, error_tab, error_code, error_msg);
            
        -- B. 同時在螢幕印出，方便手動排查
        SELECT '==========================================' AS 'Status';
        SELECT 'ERROR OCCURED & SAVED TO ERROR_LOG TABLE' AS 'Error';
        SELECT CONCAT('Error Message: ', error_msg) AS 'Details';
        SELECT CONCAT('SQL State: ', error_code) AS 'Details';
		SELECT CONCAT('Error SCHEMA: ', error_sch) AS 'Details';
        SELECT CONCAT('Error TABLE: ', error_tab) AS 'Details';
        SELECT '==========================================' AS 'Status';
    END;

    -- 3. 主程式邏輯開始
    
    SET batch_start_time = NOW();
    SELECT '================================================' AS 'Log';
    SELECT 'Loading Bronze Layer' AS 'Log';
    SELECT '================================================' AS 'Log';

    SELECT '------------------------------------------------' AS 'Log';
    SELECT 'Loading CRM Tables' AS 'Log';
    SELECT '------------------------------------------------' AS 'Log';

    -- 紀錄單表開始時間
    SET start_time = NOW();
    
    SELECT '>> Truncating Table: crm_cust_info' AS 'Log';
    TRUNCATE TABLE crm_cust_info;  -- 注意：MySQL不使用 bronze. 字首，請確保已先 USE 資料庫

    SELECT '>> Inserting Data Into: crm_cust_info' AS 'Log';
    
    -- 替代 BULK INSERT：使用 MySQL 的 LOAD DATA
    -- 注意：Windows 的路徑斜線在 MySQL 中要改成正斜線 '/' 或雙反斜線 '\\'
    SET @sql_query = CONCAT(
		"LOAD DATA INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_crm/cust_info.csv' ",
		"INTO TABLE crm_cust_info ",
		"FIELDS TERMINATED BY ',' ",
		"LINES TERMINATED BY '\r\n' ", -- Windows 檔案換行符號通常為 \r\n
		"IGNORE 1 LINES; "        -- 跳過第一行標題 (等同 FIRSTROW = 2)
	);
    
	-- 【核心修正處】：騙過編譯器，在執行當下才即時轉成實體指令執行
    PREPARE stmt FROM @sql_query; -- 準備指令 (在mysql裡面，這個用法sql_query必須是全域變數，sql server則沒限定))
    EXECUTE stmt;                -- 執行指令
    DEALLOCATE PREPARE stmt;     -- 釋放記憶體
    
    SET end_time = NOW();
    
    -- 計算並印出花費時間 (MySQL 使用 TIMESTAMPDIFF)
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS 'Log';
    SELECT '>> -------------' AS 'Log';
    
    -- 2 --
	SET start_time = NOW();
    
    SELECT '>> Truncating Table: crm_prd_info' AS 'Log';
    TRUNCATE TABLE crm_prd_info;  -- 注意：MySQL不使用 bronze. 字首，請確保已先 USE 資料庫

    SELECT '>> Inserting Data Into: crm_prd_info' AS 'Log';
    
    -- 替代 BULK INSERT：使用 MySQL 的 LOAD DATA
    -- 注意：Windows 的路徑斜線在 MySQL 中要改成正斜線 '/' 或雙反斜線 '\\'
    SET @sql_query = CONCAT(
		"LOAD DATA INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_crm/prd_info.csv' ",
		"INTO TABLE crm_prd_info ",
		"FIELDS TERMINATED BY ',' ",
		"LINES TERMINATED BY '\r\n' ", -- Windows 檔案換行符號通常為 \r\n
		"IGNORE 1 LINES; "        -- 跳過第一行標題 (等同 FIRSTROW = 2) Vince..Carter66
	);
    
	-- 【核心修正處】：騙過編譯器，在執行當下才即時轉成實體指令執行
    PREPARE stmt FROM @sql_query; -- 準備指令 (在mysql裡面，這個用法sql_query必須是全域變數，sql server則沒限定))
    EXECUTE stmt;                -- 執行指令
    DEALLOCATE PREPARE stmt;     -- 釋放記憶體
    
    SET end_time = NOW();
    
    -- 計算並印出花費時間 (MySQL 使用 TIMESTAMPDIFF)
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS 'Log';
    SELECT '>> -------------' AS 'Log';
    
    -- 3 --
    SET start_time = NOW();
    
    SELECT '>> Truncating Table: crm_sales_details' AS 'Log';
    TRUNCATE TABLE crm_sales_details;  -- 注意：MySQL不使用 bronze. 字首，請確保已先 USE 資料庫

    SELECT '>> Inserting Data Into: crm_sales_details' AS 'Log';
    
    -- 替代 BULK INSERT：使用 MySQL 的 LOAD DATA
    -- 注意：Windows 的路徑斜線在 MySQL 中要改成正斜線 '/' 或雙反斜線 '\\'
    SET @sql_query = CONCAT(
		"LOAD DATA INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_crm/sales_details.csv' ",
		"INTO TABLE crm_sales_details ",
		"FIELDS TERMINATED BY ',' ",
		"LINES TERMINATED BY '\r\n' ", -- Windows 檔案換行符號通常為 \r\n
		"IGNORE 1 LINES; "        -- 跳過第一行標題 (等同 FIRSTROW = 2)
	);
    
	-- 【核心修正處】：騙過編譯器，在執行當下才即時轉成實體指令執行
    PREPARE stmt FROM @sql_query; -- 準備指令 (在mysql裡面，這個用法sql_query必須是全域變數，sql server則沒限定))
    EXECUTE stmt;                -- 執行指令
    DEALLOCATE PREPARE stmt;     -- 釋放記憶體

    SET end_time = NOW();
    
    -- 計算並印出花費時間 (MySQL 使用 TIMESTAMPDIFF)
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS 'Log';
    SELECT '>> -------------' AS 'Log';

-- 4 --
    SET start_time = NOW();
    
    SELECT '>> Truncating Table: erp_loc_a101' AS 'Log';
    TRUNCATE TABLE erp_prd_info;  -- 注意：MySQL不使用 bronze. 字首，請確保已先 USE 資料庫

    SELECT '>> Inserting Data Into: erp_loc_a101' AS 'Log';
    
    -- 替代 BULK INSERT：使用 MySQL 的 LOAD DATA
    -- 注意：Windows 的路徑斜線在 MySQL 中要改成正斜線 '/' 或雙反斜線 '\\'
    SET @sql_query = CONCAT(
		"LOAD DATA INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_erp/loc_a101.csv' ",
		"INTO TABLE erp_loc_a101 ",
		"FIELDS TERMINATED BY ',' ",
		"LINES TERMINATED BY '\r\n' ", -- Windows 檔案換行符號通常為 \r\n
		"IGNORE 1 LINES; "        -- 跳過第一行標題 (等同 FIRSTROW = 2)
	);
    
	-- 【核心修正處】：騙過編譯器，在執行當下才即時轉成實體指令執行
    PREPARE stmt FROM @sql_query; -- 準備指令 (在mysql裡面，這個用法sql_query必須是全域變數，sql server則沒限定))
    EXECUTE stmt;                -- 執行指令
    DEALLOCATE PREPARE stmt;     -- 釋放記憶體

    SET end_time = NOW();
    
    -- 計算並印出花費時間 (MySQL 使用 TIMESTAMPDIFF)
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS 'Log';
    SELECT '>> -------------' AS 'Log';
    
    -- 5 --
	SET start_time = NOW();
    
    SELECT '>> Truncating Table: erp_cust_az12' AS 'Log';
    TRUNCATE TABLE erp_cust_az12;  -- 注意：MySQL不使用 bronze. 字首，請確保已先 USE 資料庫

    SELECT '>> Inserting Data Into: erp_cust_az12' AS 'Log';
    
    -- 替代 BULK INSERT：使用 MySQL 的 LOAD DATA
    -- 注意：Windows 的路徑斜線在 MySQL 中要改成正斜線 '/' 或雙反斜線 '\\'
    SET @sql_query = CONCAT(
		"LOAD DATA INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_erp/cust_az12.csv' ",
		"INTO TABLE erp_cust_az12 ",
		"FIELDS TERMINATED BY ',' ",
		"LINES TERMINATED BY '\r\n' ", -- Windows 檔案換行符號通常為 \r\n
		"IGNORE 1 LINES; "        -- 跳過第一行標題 (等同 FIRSTROW = 2)
	);
    
	-- 【核心修正處】：騙過編譯器，在執行當下才即時轉成實體指令執行
    PREPARE stmt FROM @sql_query; -- 準備指令 (在mysql裡面，這個用法sql_query必須是全域變數，sql server則沒限定))
    EXECUTE stmt;                -- 執行指令
    DEALLOCATE PREPARE stmt;     -- 釋放記憶體

    SET end_time = NOW();
    
    -- 計算並印出花費時間 (MySQL 使用 TIMESTAMPDIFF)
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS 'Log';
    SELECT '>> -------------' AS 'Log';
    
    -- 6 --
	SET start_time = NOW();
    
    SELECT '>> Truncating Table: erp_px_cat_g1v2' AS 'Log';
    TRUNCATE TABLE erp_px_cat_g1v2;  -- 注意：MySQL不使用 bronze. 字首，請確保已先 USE 資料庫

    SELECT '>> Inserting Data Into: erp_px_cat_g1v2' AS 'Log';
    
    -- 替代 BULK INSERT：使用 MySQL 的 LOAD DATA
    -- 注意：Windows 的路徑斜線在 MySQL 中要改成正斜線 '/' 或雙反斜線 '\\'
    SET @sql_query = CONCAT(
		"LOAD DATA INFILE 'C:/Users/ww813/Downloads/sql-data-warehouse-project/sql-data-warehouse-project/datasets/source_erp/px_cat_g1v2.csv' ",
		"INTO TABLE erp_px_cat_g1v2 ",
		"FIELDS TERMINATED BY ',' ",
		"LINES TERMINATED BY '\r\n' ", -- Windows 檔案換行符號通常為 \r\n
		"IGNORE 1 LINES; "        -- 跳過第一行標題 (等同 FIRSTROW = 2)
	);
    
	-- 【核心修正處】：騙過編譯器，在執行當下才即時轉成實體指令執行
    PREPARE stmt FROM @sql_query; -- 準備指令 (在mysql裡面，這個用法sql_query必須是全域變數，sql server則沒限定))
    EXECUTE stmt;                -- 執行指令
    DEALLOCATE PREPARE stmt;     -- 釋放記憶體

    SET end_time = NOW();
    
    -- 計算並印出花費時間 (MySQL 使用 TIMESTAMPDIFF)
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, start_time, end_time), ' seconds') AS 'Log';
    SELECT '>> -------------' AS 'Log';

    -- 批次結束
    SET batch_end_time = NOW();
    SELECT '==========================================' AS 'Log';
    SELECT 'Loading Bronze Layer is Completed' AS 'Log';
    SELECT CONCAT(' - Total Load Duration: ', TIMESTAMPDIFF(SECOND, batch_start_time, batch_end_time), ' seconds') AS 'Log';
    SELECT '==========================================' AS 'Log';

END$$

DELIMITER ;

CALL load_bronze();

SELECT COUNT(*) FROM bronze.crm_cust_info;

SELECT * FROM bronze.error_log;
*/

/*  "sql server syntax"
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '================================================';
		PRINT 'Loading Bronze Layer'; 
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\sql\dwh_project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\sql\dwh_project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\sql\dwh_project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\sql\dwh_project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\sql\dwh_project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\sql\dwh_project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
*/
