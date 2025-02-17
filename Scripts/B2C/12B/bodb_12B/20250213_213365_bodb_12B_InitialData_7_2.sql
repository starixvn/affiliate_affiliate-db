/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250213@Eddie
	DB: DB12B-bodb_12B
	Task: Update initial data for bodb_12B DB [RedmineId : #212201]

*/
USE bodb_12B
GO

UPDATE dbo.API_TimeTracker
SET KeyValue = '{"Id":1,"UpdateTime":"2025-01-01T00:00:00.000"}'
WHERE DataSource = 'DepositInfo'
GO