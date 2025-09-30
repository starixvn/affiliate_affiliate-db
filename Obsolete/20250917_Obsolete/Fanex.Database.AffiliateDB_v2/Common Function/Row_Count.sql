CREATE FUNCTION Row_Count (@table_name sysname)
-- @table_name we want to get count

RETURNS bigint
/*
-------------------------------------------------------
-- Function Name: row_count
-- Author: Mohamed Hassan
-- Email: moh_hassan20@yahoo.com
-- Development Date: 08/11/2008
-- Version: 1.0
-- Description: Return row count of the whole table, as a replacement for count(*) , give extra performance  at least 70% over , than count(*) for large tables with millions of rows
-- SQL Server: SQL server 2005
-- Usage Example: select dbo.row_count ('Sales.SalesOrderDetail')
-- Copyright:
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-------------------------------------------------------
*/
AS
BEGIN
DECLARE @nn bigint -- number of rows

IF @table_name IS NOT NULL 
BEGIN
 SELECT  @nn = sum(  p.rows )  
 FROM sys.partitions p
 LEFT JOIN  sys.allocation_units a ON  p.partition_id = a.container_id
 WHERE
  p.index_id  in(0,1) -- 0 heap table , 1 table with clustered index
       and p.rows is not null
  and a.type = 1  -- row-data only , not LOB
  and p.object_id = object_id(@table_name)    
 END 
RETURN (@nn)
END
GO