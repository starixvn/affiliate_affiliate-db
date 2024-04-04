/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240404@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		ReInitial data Tracker Customer for YashBet
*/
DELETE c 
FROM dbo.API_TimeTracker c (ROWLOCK)
WHERE DataSource IN ('Customer')
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource, CalledTime, KeyValue
FROM (
	SELECT 'Customer'AS DataSource, '2024-01-01 04:09:11'AS CalledTime, '2024-01-01T00:00:00.000' AS KeyValue
)t 
