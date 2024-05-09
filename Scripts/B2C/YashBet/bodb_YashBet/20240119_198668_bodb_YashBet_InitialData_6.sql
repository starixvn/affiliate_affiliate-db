/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		4. Initial data for bodb_YashBet DB
*/
USE bodb_YashBet
GO

INSERT INTO dbo.SystemSettings (SName, SValue)
SELECT T.SName, T.SValue
FROM (
	SELECT 'ArchiveData_Date' AS SName, '2024-01-01'AS SValue
	UNION ALL
	SELECT 'UpdatedCustomer_Date' AS SName, '2024-01-20 00:00:00'AS SValue
)t
	LEFT JOIN dbo.SystemSettings ss WITH (NOLOCK) ON ss.SName = t.SValue
WHERE ss.SValue IS NULL
GO
INSERT INTO TpExchange (TpExchangeId, ExchangeId)
SELECT T.TpExchangeId, T.ExchangeId
FROM (
	SELECT 74 AS TpExchangeId, 97 AS ExchangeId
)t 
	LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON T.TpExchangeId = te.TpExchangeId
											AND T.ExchangeId = te.ExchangeId
WHERE te.TpExchangeId IS NULL
GO
INSERT INTO dbo.TpGameType (Type, TypeName)
	SELECT t.Type, t.TypeName
	FROM bodb_N88.dbo.TpGameType t WITH (NOLOCK)
		LEFT JOIN dbo.TpGameType tgt WITH (NOLOCK) ON T.Type = tgt.Type
	WHERE tgt.Type IS NULL
GO
INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource, CalledTime, KeyValue
FROM (
	SELECT 'BonusInfo'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '10' AS KeyValue UNION ALL
	SELECT 'DepositInfo'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '{"Id":1,"UpdateTime":"2024-01-01T00:00:00"}' AS KeyValue UNION ALL
	SELECT 'RebateMLog'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'TpBetRecord'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'TpReport9W'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'TpWager9W'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'WithdrawalInfo'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue UNION ALL
	SELECT 'Customer'AS DataSource, '2024-01-01 4:09:11'AS CalledTime, '2024-01-01 00:00:00' AS KeyValue 
)t 
GO