/*
	Setting of Products: launch date, data source (table), ...
*/

UPDATE dbo.SystemSettings WITH (NOLOCK)

SELECT * FROM dbo.APIProductSettings WITH (NOLOCK)

-- Check raw data before
SELECT * FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)

SELECT * FROM dbo.bettrans_Betsoft WITH (NOLOCK)

-- Run job import raw data
EXEC dbo.Task_APIProduct_ImportQueue_Process_Job

-- Check raw data after
SELECT * FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)

SELECT * FROM dbo.bettrans_Betsoft WITH (NOLOCK)

-- Run job import rptMemberDaily
EXEC dbo.Task_Aff_ImportData_API_Job

-- Per product
--EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = 10, @WInlostdate = '2018-10-31'