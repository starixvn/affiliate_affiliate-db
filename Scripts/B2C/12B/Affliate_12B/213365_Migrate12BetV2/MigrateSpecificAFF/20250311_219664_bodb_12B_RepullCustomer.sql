/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250311@Sally
	DB: DB12B-bodb_12B
	Task: Repull Customer [RedmineId : #219664]

*/
USE bodb_12B
GO
DELETE c 
FROM dbo.API_TimeTracker c
WHERE DataSource = 'Customer'
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT t.DataSource, '2025-03-10' AS CalledTime, t.KeyValue
FROM(
	SELECT 'Customer'AS DataSource,	'2009-09-15T00:00:00.000' AS KeyValue 
)t
GO

