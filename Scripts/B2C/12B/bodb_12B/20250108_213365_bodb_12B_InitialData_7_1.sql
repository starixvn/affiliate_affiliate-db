/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20241118@Eddie
	DB: DB12B-bodb_12B
	Task: Initial data for bodb_12B DB [RedmineId : #212201]

*/
USE bodb_12B
GO

/****** Object: Table [API_TimeTracker] ******/
DECLARE @beginofmonth DATETIME
SELECT @beginofmonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)

INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT t.DataSource, t.CalledTime, t.KeyValue
FROM (
		SELECT 'BonusInfo'		 , @beginofmonth, '1'
		UNION ALL
		SELECT 'RebateMLog'	 	 , @beginofmonth, '2025-02-01T00:00:00.000'
		UNION ALL
		SELECT 'TpBetRecord'	 , @beginofmonth, '2025-02-01T00:00:00.000'
		UNION ALL
		SELECT 'TpReport9W'	 	 , @beginofmonth, '2025-02-01T00:00:00.000'
		UNION ALL
		SELECT 'TpWager9W'		 , @beginofmonth, '2025-02-01T00:00:00.000'
		UNION ALL
		SELECT 'WithdrawalInfo'  , @beginofmonth, '2025-02-01T00:00:00.000'
		UNION ALL
		SELECT 'Customer'		 , @beginofmonth, '2008-03-12T00:00:00.000'
		UNION ALL
		SELECT 'DepositInfo'	 , @beginofmonth, '{"Id":1,"UpdateTime":"2025-02-01T00:00:00.000"}'
		UNION ALL
		SELECT 'WeeklyBonusInfo' , @beginofmonth, '{"Date":"2025-02-01T00:00:00.000-04:00","PageIndex":0}'
) AS t(DataSource, CalledTime, KeyValue)
	LEFT JOIN dbo.API_TimeTracker tt WITH (NOLOCK) ON tt.DataSource = t.DataSource
												  AND tt.CalledTime = t.CalledTime
WHERE tt.DataSource IS NULL
   OR tt.CalledTime IS NULL

/* Need update column [KeyValue] with DepositInfo and WeeklyBonusInfo when script be released */
GO