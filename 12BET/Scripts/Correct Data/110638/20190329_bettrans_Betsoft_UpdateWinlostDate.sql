USE [Affiliate_12BET]
GO

/*
	Created: 20190329@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Betsoft - Manually update raw data - Get winlostdate by StartDate, confirm from #107979
	RedmineID: #110638
*/

-- Betsoft: GMT+0
-- 309886 rows
UPDATE dbo.bettrans_Betsoft WITH (ROWLOCK, UPDLOCK)
SET StartDate = DATEADD(HOUR, 4, StartDate)
	,EndDate = DATEADD(HOUR, 4, EndDate)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 4, StartDate))
WHERE WinlostDate >= '2019-02-28'
	AND DATEADD(HOUR, 4, StartDate) >= '2019-03-01'