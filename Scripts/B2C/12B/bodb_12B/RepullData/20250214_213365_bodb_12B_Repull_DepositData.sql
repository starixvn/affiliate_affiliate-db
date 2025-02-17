/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250214@Sally
	DB: DB12B-bodb_12B
	Task: Repull DepositData [RedmineId : #212201]

*/
USE bodb_12B
GO
DELETE c 
FROM dbo.API_TimeTracker c
WHERE DataSource = 'DepositInfo'
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT t.DataSource, '2025-02-13' AS CalledTime, t.KeyValue
FROM(
	SELECT 'DepositInfo' as DataSource, '{"Id":9354674,"UpdateTime":"2025-02-12T00:00:00.000"}' as KeyValue
)t
GO

