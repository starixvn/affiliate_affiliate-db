/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250217@Eddie
	DB: DB12B-bodb_12B
	Task: Insert initial data for bodb_12B DB [RedmineId : #212201]

*/
USE bodb_12B
GO


DELETE c
FROM API_TimeTracker c
WHERE DataSource  IN ('TpBetRecord', 'TpReport9W', 'TpWager9W')

DECLARE @beginofmonth DATETIME
SELECT @beginofmonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT t.DataSource, t.CalledTime, t.KeyValue
FROM (
	SELECT 'TpBetRecord' , @beginofmonth, '2025-02-01T00:00:00.000'
	UNION ALL               
	SELECT 'TpReport9W'	 , @beginofmonth, '2025-02-01T00:00:00.000'
	UNION ALL               
	SELECT 'TpWager9W'	 , @beginofmonth, '2025-02-01T00:00:00.000'
) AS t(DataSource, CalledTime, KeyValue)
GO