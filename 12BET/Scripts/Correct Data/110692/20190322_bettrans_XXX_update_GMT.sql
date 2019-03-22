USE [Affiliate_12BET]
GO

/*
	Created: 20190322@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Manually update raw data
*/

DECLARE @FromDate SMALLDATETIME
SELECT  @FromDate = '2019-03-01'

-- Betsoft: GMT+0
-- 309886 rows
UPDATE dbo.bettrans_Betsoft WITH (ROWLOCK, UPDLOCK)
SET BetTime = DATEADD(HOUR, 4, BetTime)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 4, BetTime))
WHERE WinlostDate >= @FromDate
	AND DATEADD(HOUR, 4, BetTime) >= @FromDate

-- Ebet: GMT+8
-- 235233 rows
UPDATE dbo.bettrans_Ebet WITH (ROWLOCK, UPDLOCK)
SET PayoutTime = DATEADD(HOUR, 12, PayoutTime)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 12, PayoutTime))
WHERE WinlostDate >= @FromDate
	AND DATEADD(HOUR, 12, PayoutTime) >= @FromDate

-- Crystal: GMT+8
-- 111526 rows
UPDATE dbo.bettrans_Crystal WITH (ROWLOCK, UPDLOCK)
SET changeTime = DATEADD(HOUR, 12, changeTime)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 12, changeTime))
WHERE WinlostDate >= @FromDate
	AND DATEADD(HOUR, 12, changeTime) >= @FromDate

-- iSoftbet: GMT+0
-- 82260 rows
UPDATE dbo.bettrans_iSoftbet WITH (ROWLOCK, UPDLOCK)
SET [TIME] = DATEADD(HOUR, 4, [TIME])
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 4, [TIME]))
WHERE WinlostDate >= @FromDate
	AND DATEADD(HOUR, 4, [TIME]) >= @FromDate

-- OPUS: GMT+8
-- 711195 rows
UPDATE dbo.bettrans_OPUS WITH (ROWLOCK, UPDLOCK)
SET transaction_date_time = DATEADD(HOUR, 12, transaction_date_time)
	,stamp_date = DATEADD(HOUR, 12, stamp_date)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 12, transaction_date_time))
WHERE WinlostDate >= @FromDate
	AND DATEADD(HOUR, 12, transaction_date_time) >= @FromDate