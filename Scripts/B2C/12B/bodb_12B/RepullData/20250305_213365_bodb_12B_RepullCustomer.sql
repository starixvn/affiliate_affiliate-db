/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250306@Sally
	DB: DB12B-bodb_12B
	Task: Repull Customer [RedmineId : #212201]

*/
USE bodb_12B
GO
DELETE c 
FROM dbo.API_TimeTracker c
WHERE DataSource = 'Customer'
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT t.DataSource, '2025-03-05' AS CalledTime, t.KeyValue
FROM(
	SELECT 'Customer'AS DataSource,	'2011-02-01T00:00:00.000' AS KeyValue 
)t
GO

