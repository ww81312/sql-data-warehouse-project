/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

-- 1. 如果存在名為 'DataWarehouse' 的資料庫（Schema），就把它刪除
DROP DATABASE IF EXISTS DataWarehouse;

-- 2. 建立全新的 'DataWarehouse' 資料庫
CREATE DATABASE DataWarehouse;

-- 3. 切換到該資料庫，接下來的指令都會在裡面執行
USE DataWarehouse;

-- Create Schemas
CREATE SCHEMA bronze;

CREATE SCHEMA silver;

CREATE SCHEMA gold;
