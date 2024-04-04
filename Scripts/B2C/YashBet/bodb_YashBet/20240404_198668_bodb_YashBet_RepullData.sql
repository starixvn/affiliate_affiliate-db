/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240404@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		ReInitial data Tracker for YashBet
*/
DELETE c 
FROM dbo.API_TimeTracker c (ROWLOCK)
WHERE DataSource IN ('TpReport9W','TpWager9W','DepositInfo','TpBetRecord')
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource, CalledTime, KeyValue
FROM (
	SELECT 'DepositInfo'AS DataSource, '2024-01-01 04:09:11'AS CalledTime, '{"Id":1,"UpdateTime":"2024-01-01T00:00:00.000"}' AS KeyValue UNION ALL
	SELECT 'TpBetRecord'AS DataSource, '2024-01-01 04:09:11'AS CalledTime, '2024-01-01T00:00:00.000' AS KeyValue UNION ALL
	SELECT 'TpReport9W'AS DataSource, '2024-01-01 04:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'TpWager9W'AS DataSource, '2024-01-01 04:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue
)t 
