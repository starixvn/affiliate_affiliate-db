USE Affiliate_12BET --Enter the name of the database you want to reindex

		DECLARE @TableName varchar(255)

		DECLARE TableCursor CURSOR FOR
		SELECT table_name FROM information_schema.tables
		WHERE table_type = 'base table'

		OPEN TableCursor

		FETCH NEXT FROM TableCursor INTO @TableName
		WHILE @@FETCH_STATUS = 0
		BEGIN
		DBCC DBREINDEX(@TableName,' ',90)
		FETCH NEXT FROM TableCursor INTO @TableName
		END

		CLOSE TableCursor

		DEALLOCATE TableCursor



/*
 Method 2:
Execute the following Microsoft SQL Server T-SQL database administration script in SSMS Query Editor to REBUILD all indexes in the AdventureWorks2008 sample database.*/

-- SQL Server 2008 script to REBUILD all indexes for all tables --Offline



USE Affiliate_12BET;

DECLARE @DatabaseName SYSNAME,  @TableName VARCHAR(256) ,@DynamicSQL NVARCHAR(max),@FILLFACTOR INT



select     @FILLFACTOR  = 85,@DatabaseName= DB_NAME(), @DynamicSQL='DECLARE curAllTablesInDB CURSOR FOR SELECT TABLE_SCHEMA +

 ''.'' + TABLE_NAME AS TABLENAME  

 FROM ' + @DatabaseName + '.INFORMATION_SCHEMA.TABLES WHERE

 TABLE_TYPE = ''BASE TABLE'''  
 

BEGIN 

  EXEC sp_executeSQL @DynamicSQL  -- create tables cursor

  OPEN curAllTablesInDB  

  FETCH NEXT FROM curAllTablesInDB INTO @TableName  

  WHILE (@@FETCH_STATUS = 0) 

  BEGIN  

	   SET @DynamicSQL = 'ALTER INDEX ALL ON ' + @TableName +

		 ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR,@FILLFACTOR) + ')' 

	   PRINT @DynamicSQL

	   

	   EXEC sp_executeSQL @DynamicSQL 

	   FETCH NEXT FROM curAllTablesInDB INTO @TableName  

   END   -- cursor WHILE

   CLOSE curAllTablesInDB  

   DEALLOCATE curAllTablesInDB 

END
-- INDEX REBUILD ONLINE

USE Affiliate_12BET;

GO

CREATE PROC sprocDBIndexREBUILD @FILLFACTOR INT = 90

AS

BEGIN

DECLARE @DatabaseName SYSNAME,  @TableName VARCHAR(256) ,@DynamicSQL NVARCHAR(max)

 

select     @DatabaseName= DB_NAME(), @DynamicSQL='DECLARE curAllTablesInDB CURSOR FOR SELECT TABLE_SCHEMA +

 ''.'' + TABLE_NAME AS TABLENAME  

 FROM ' + @DatabaseName + '.INFORMATION_SCHEMA.TABLES WHERE

 TABLE_TYPE = ''BASE TABLE'''  
BEGIN 

  EXEC sp_executeSQL @DynamicSQL  -- create tables cursor

  OPEN curAllTablesInDB  

  FETCH NEXT FROM curAllTablesInDB INTO @TableName  

  WHILE (@@FETCH_STATUS = 0) 

  BEGIN  

	   SET @DynamicSQL = 'ALTER INDEX ALL ON ' + @TableName +

		 ' REBUILD WITH (ONLINE=ON, FILLFACTOR = ' + CONVERT(VARCHAR,@FILLFACTOR) + ')' 

	   -- PRINT @DynamicSQL

	   EXEC sp_executeSQL @DynamicSQL 

	   FETCH NEXT FROM curAllTablesInDB INTO @TableName  

   END   -- cursor WHILE

   CLOSE curAllTablesInDB  

   DEALLOCATE curAllTablesInDB 

END

END -- sproc

GO
------------

-- Index fragmentation report

SELECT SCHEMA_NAME(o.schema_id)     AS SchemaName,

	   OBJECT_NAME(a.object_id)     AS TableName,

	   i.name                       AS IndexName,

	   a.index_id                   AS IndexID,

	   convert(tinyint,a.avg_fragmentation_in_percent) AS [Fragment%]

FROM   sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL,

	   NULL, 'LIMITED') AS a

	   INNER JOIN sys.indexes i

		 ON i.index_id = a.index_id

		 AND i.object_id = a.object_id 

	   INNER JOIN sys.objects o

		 ON a.object_id = o.object_id

ORDER BY SchemaName, TableName, IndexID


----Method 3

DECLARE @Database VARCHAR(255)  
DECLARE @Table VARCHAR(255)  
DECLARE @cmd NVARCHAR(500)  
DECLARE @fillfactor INT

SET @fillfactor = 90

DECLARE DatabaseCursor CURSOR FOR  
SELECT name FROM MASTER.dbo.sysdatabases  
WHERE name NOT IN ('master','msdb','tempdb','model','distribution')  
ORDER BY 1  

OPEN DatabaseCursor  

FETCH NEXT FROM DatabaseCursor INTO @Database  
WHILE @@FETCH_STATUS = 0  
BEGIN  

   SET @cmd = 'DECLARE TableCursor CURSOR FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +
  table_name + '']'' as tableName FROM ' + @Database + '.INFORMATION_SCHEMA.TABLES
  WHERE table_type = ''BASE TABLE'''  

   -- create table cursor  
   EXEC (@cmd)  
   OPEN TableCursor  

   FETCH NEXT FROM TableCursor INTO @Table  
   WHILE @@FETCH_STATUS = 0  
   BEGIN  

	   IF (@@MICROSOFTVERSION / POWER(2, 24) >= 9)
	   BEGIN
		   -- SQL 2005 or higher command
		   SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'
		   EXEC (@cmd)
	   END
	   ELSE
	   BEGIN
		  -- SQL 2000 command
		  DBCC DBREINDEX(@Table,' ',@fillfactor)  
	   END

	   FETCH NEXT FROM TableCursor INTO @Table  
   END  

   CLOSE TableCursor  
   DEALLOCATE TableCursor  

   FETCH NEXT FROM DatabaseCursor INTO @Database  
END  
CLOSE DatabaseCursor  
DEALLOCATE DatabaseCursor 
