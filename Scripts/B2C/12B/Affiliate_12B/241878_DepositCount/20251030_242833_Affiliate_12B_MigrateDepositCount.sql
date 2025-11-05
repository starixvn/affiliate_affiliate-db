/*<info serverAlias="DBAFF12B-Affiliate_12B" viewers=""></info>*/
/*
	Created:      20251030@Sally
	Task:         Migrate DepositCount column in rptMemberDaily [#242833]
	DB:           DBAFF12B-Affiliate_12B

	Description:
		- Updates DepositCount column in dbo.rptMemberDaily from begin upto now 2025
		- Uses exact logic from Task_Aff_ImportData SP (rows 187-208)
		- Only updates ProductId = -1 records (non-gaming transactions)
		- Sets DepositCount = 0 for case value is NULL

*/

USE Affiliate_12B;

-- Get system timezone setting (from Task_Aff_ImportData logic)
DECLARE @TimeZone SMALLINT
    , @FromDate SMALLDATETIME = '2025-02-13'
    , @ToDate SMALLDATETIME = CAST (DATEADD(HOUR, 12, GETDATE()) AS DATE)
    , @FDateGMT0 SMALLDATETIME
    , @TDateGMT0 SMALLDATETIME

SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
FROM dbo.SystemSettings WITH (NOLOCK) 
WHERE SName = 'TimeZone';

SELECT @FDateGMT0 = DATEADD(HOUR, -@TimeZone, @FromDate);
SELECT @TDateGMT0 = DATEADD(HOUR, -@TimeZone, DATEADD(DAY, 1, @ToDate));

PRINT 'TimeZone setting: ' + CAST(@TimeZone AS VARCHAR(10));
PRINT 'Starting DepositCount migration from Oct 2025...';

-- Extract DepositCount calculation from rows 187-208 of Task_Aff_ImportData into temp table
CREATE TABLE #tmp_DepositCount
(
	CustId			INT,
	AffId			INT,
	DepositCount	INT,
	WinlostDate		SMALLDATETIME
);

-- Create nonclustered index for performance
CREATE NONCLUSTERED INDEX IX_tmp_DepositCount_Key 
ON #tmp_DepositCount (CustId, AffId, WinlostDate);

-- Insert DepositCount data using exact logic from Task_Aff_ImportData (rows 187-208)
INSERT INTO #tmp_DepositCount
(
	CustId,
	AffId,
	DepositCount,
	WinlostDate
)
SELECT mi.CustId,
	mi.AffId,
	COUNT(1) AS DepositCount,
    CONVERT(DATE, DATEADD(HOUR, @TimeZone, d.CreateTime)) AS WinlostDate
FROM bodb_12B.dbo.DepositInfo d WITH (NOLOCK) 
	INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
WHERE d.WinlostDate >= DATEADD(DAY, -1,  @FromDate)
	AND d.WinlostDate < DATEADD(DAY, 1, @ToDate)
	AND d.Status = 3
	AND d.CreateTime >= @FDateGMT0
    AND d.CreateTime < @TDateGMT0
GROUP BY mi.CustId,
		mi.Currency,
		mi.AffId,
        CONVERT(DATE, DATEADD(HOUR, @TimeZone, d.CreateTime))

PRINT 'Extracted DepositCount data to temp table: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';

DECLARE @WinlostFromDate SMALLDATETIME = NULL
, @WinlostToDate SMALLDATETIME = NULL
, @WinlostDate SMALLDATETIME = NULL

SELECT @WinlostFromDate = MIN(WinlostDate)
    ,@WinlostToDate = MAX(WinlostDate)
FROM #tmp_DepositCount

IF(@WinlostFromDate IS NULL)
BEGIN
    PRINT 'No DepositCount data found to update. Exiting migration.';
    DROP TABLE IF EXISTS #tmp_DepositCount;
    RETURN;
END
SELECT @WinlostDate = @WinlostFromDate

PRINT 'Starting Update DepositCount ...'
WHILE (@WinlostDate <= @WinlostToDate)
BEGIN
    -- Update DepositCount for non-gaming transactions (ProductId = -1) from temp table
    UPDATE r WITH (UPDLOCK, ROWLOCK)
    SET DepositCount = dc.DepositCount
    FROM dbo.rptMemberDaily r
        INNER JOIN #tmp_DepositCount dc ON r.CustId = dc.CustId AND r.AffId = dc.AffId AND r.WinlostDate = dc.WinlostDate
    WHERE dc.WinlostDate = @WinlostDate
        AND r.ProductId = -1;

    -- Set DepositCount = 0 for gaming transactions (ProductId <> -1)
    UPDATE dbo.rptMemberDaily WITH (UPDLOCK, ROWLOCK)
    SET DepositCount = 0
    WHERE WinlostDate = @WinlostDate
        AND DepositCount IS NULL;

    PRINT CONCAT('WinlostDate: ', @WinlostDate);
	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
PRINT 'Migration completed successfully!';

-- Clean up temporary table
DROP TABLE IF EXISTS #tmp_DepositCount;
