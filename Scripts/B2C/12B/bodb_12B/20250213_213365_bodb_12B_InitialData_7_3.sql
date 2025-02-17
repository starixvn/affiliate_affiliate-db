/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250213@Eddie
	DB: DB12B-bodb_12B
	Task: Insert initial data for bodb_12B DB [RedmineId : #212201]

*/
USE bodb_12B
GO


DELETE c
FROM API_TimeTracker c
WHERE DataSource  = 'Customer'

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource,'2025-02-13 00:00:00' AS CalledTime, KeyValue
FROM (
	SELECT 'Customer' AS DataSource, '2008-03-12T01:00:00.000' AS KeyValue 
)t 
GO