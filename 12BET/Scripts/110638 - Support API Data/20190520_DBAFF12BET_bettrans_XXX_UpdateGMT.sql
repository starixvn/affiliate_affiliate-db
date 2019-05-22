USE [Affiliate_12BET]
GO

/*
	Created: 20190520@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Manually update raw data
*/

-- Betsoft: GMT+0 (from GMT-4)
-- 25136 rows
DECLARE @WinlostDate SMALLDATETIME
SELECT  @WinlostDate = '2019-02-28'

UPDATE dbo.bettrans_Betsoft WITH (ROWLOCK)
SET BetTime = DATEADD(HOUR, 4, BetTime)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 4, BetTime))
WHERE WinlostDate = @WinlostDate
	AND DATEADD(HOUR, 4, BetTime) > @WinlostDate
GO

-- Ebet: GMT+8 (from GMT-4)
-- 13794 rows
DECLARE @WinlostDate SMALLDATETIME
SELECT  @WinlostDate = '2019-02-28'

UPDATE dbo.bettrans_Ebet WITH (ROWLOCK)
SET PayoutTime = DATEADD(HOUR, 12, PayoutTime)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 12, PayoutTime))
WHERE WinlostDate = @WinlostDate
	AND DATEADD(HOUR, 12, PayoutTime) > @WinlostDate
GO

-- Crystal: GMT+8 (from GMT-4)
-- 6174 rows
DECLARE @WinlostDate SMALLDATETIME
SELECT  @WinlostDate = '2019-02-28'

UPDATE dbo.bettrans_Crystal WITH (ROWLOCK)
SET changeTime = DATEADD(HOUR, 12, changeTime)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 12, changeTime))
WHERE WinlostDate = @WinlostDate
	AND DATEADD(HOUR, 12, changeTime) > @WinlostDate
GO

-- iSoftbet: GMT+0 (from GMT-4)
-- 7990 rows
DECLARE @WinlostDate SMALLDATETIME
SELECT  @WinlostDate = '2019-02-28'

UPDATE dbo.bettrans_iSoftbet WITH (ROWLOCK)
SET [TIME] = DATEADD(HOUR, 4, [TIME])
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 4, [TIME]))
WHERE WinlostDate = @WinlostDate
	AND DATEADD(HOUR, 4, [TIME]) > @WinlostDate
GO

-- OPUS: GMT-4 (from GMT+8)
-- 1053446 rows
DECLARE @WinlostDate SMALLDATETIME
SELECT  @WinlostDate = '2019-02-28'

UPDATE dbo.bettrans_OPUS WITH (ROWLOCK)
SET transaction_date_time = DATEADD(HOUR, 12, transaction_date_time)
	,stamp_date = DATEADD(HOUR, 12, stamp_date)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, 12, transaction_date_time))
WHERE WinlostDate = @WinlostDate
	AND DATEADD(HOUR, 12, transaction_date_time) > @WinlostDate

UPDATE dbo.bettrans_OPUS WITH (ROWLOCK)
SET transaction_date_time = DATEADD(HOUR, -12, transaction_date_time)
	,stamp_date = DATEADD(HOUR, -12, stamp_date)
	,WinlostDate = CONVERT(DATE, DATEADD(HOUR, -12, transaction_date_time))
WHERE WinlostDate > @WinlostDate
GO