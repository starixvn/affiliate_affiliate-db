/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240404@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		ReInitial data Tracker for YashBet
*/
TRUNCATE TABLE dbo.API_TimeTracker
GO

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource, CalledTime, KeyValue
FROM (
	SELECT 'BonusInfo'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '10' AS KeyValue UNION ALL
	SELECT 'DepositInfo'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '{"Id":1,"UpdateTime":" 2024-01-01T00:00:00.000"}' AS KeyValue UNION ALL
	SELECT 'RebateMLog'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'TpBetRecord'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, ' 2024-01-01T00:00:00.000' AS KeyValue UNION ALL
	SELECT 'TpReport9W'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'TpWager9W'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'WithdrawalInfo'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'Customer'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue 
)t 
