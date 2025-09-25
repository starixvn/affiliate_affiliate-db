/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20250922@Sally
	DB: DBN88-bodb_N88
	Task: Repull Customer [RedmineId : #238812]
	

*/
-- Run on DB052, DB053
USE bodb_N88
GO
DELETE c 
FROM dbo.API_TimeTracker c WITH (ROWLOCK)
WHERE DataSource = 'Customer'
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT t.DataSource, '2025-09-20' AS CalledTime, t.KeyValue
FROM(
	SELECT 'Customer'AS DataSource,	'2025-09-01T00:00:00.000' AS KeyValue 
)t
GO
