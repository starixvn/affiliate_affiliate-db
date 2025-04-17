/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250411@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Enhance Get BBF by TimeZone [RedmineID: #222401]

*/

USE Affiliate_N8B
GO

-- Add columns WinlostDate SMALLTIME null to table AffTrans
	ALTER TABLE dbo.AffTrans
	ADD WinlostDate SMALLDATETIME NULL
GO

-- Update data on WinlostDate column on table AffTrans: get from data TransDate column(timezone GMT-4) change to timezone GMT+8 and then only get DATE only

	CREATE TABLE #Data_TransId (Row_num INT IDENTITY(1,1), TransId BIGINT)
	SELECT COUNT(1) FROM dbo.AffTrans WITH(NOLOCK)
	-- Affiliate_N88: ~ 21k4 rows
	-- Affiliate_N8G: ~ 6k3 rows
	-- Affiliate_N8B: ~ 4k1 rows
	INSERT INTO #Data_TransId(TransId)
		SELECT TransId
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE WinlostDate IS NULL

	------ info for deployer
	DECLARE @StartRow	INT 
		, @StopRow		INT 
		, @MaxRow		INT				= 0
		, @Threshold	INT				-- the number of each batch
		, @MessageError VARCHAR(50)		= NULL
		, @ErrorCode	INT				= 0

	SET @Threshold		= 4000
 
	SELECT @MaxRow = MAX(Row_num) 
	FROM #Data_TransId

	IF (@Threshold >= @MaxRow)
		SET @Threshold = @MaxRow

	-- SET for first batch
	SELECT @StartRow = 1, @StopRow = @Threshold

	WHILE (@MaxRow IS NOT NULL)
	BEGIN
			Print 'Starting Migrate'
			PRINT @StartRow 
			PRINT @StopRow
		
			-- YOUR CODE PROCESS FOR DATA FROM @StartRow & @StopRow
			UPDATE c SET WinlostDate = CAST(CONVERT(VARCHAR(10), DATEADD(HOUR, 12, c.TransDate), 120) AS SMALLDATETIME)
			FROM dbo.AffTrans c WITH (UPDLOCK, ROWLOCK)
				INNER JOIN #Data_TransId a ON c.TransId = a.TransId
			WHERE a.Row_num BETWEEN @StartRow AND @StopRow

			SET @MessageError = CONVERT(VARCHAR(50), GETDATE(), 121)			
			RAISERROR (@MessageError, 0, 1) WITH NOWAIT
		
			IF @StopRow = @MaxRow BREAK

			WAITFOR DELAY '00:00:00.100' --optional

			SET @StartRow = @StopRow + 1
			SET @StopRow = @StopRow + @Threshold
			IF @StopRow >= @MaxRow
				SET @StopRow = @MaxRow
	END

DROP TABLE #Data_TransId
GO
-- add contrainst to WinlostDate column on table AffTrans default value getdate()
ALTER TABLE dbo.AffTrans
ADD CONSTRAINT DF_AffTrans_WinlostDate DEFAULT CAST(GETDATE() AS DATE)  FOR WinlostDate
GO
    -- update column WinlostDate to not null
    ALTER TABLE dbo.AffTrans
    ALTER COLUMN WinlostDate SMALLDATETIME NOT NULL
GO

-- Create new non-index on AffTrans table
	CREATE NONCLUSTERED INDEX IX_AffTrans_AffId_WinlostDate_Status
	ON dbo.AffTrans (AffId, WinlostDate, [Status])
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [AffData ] ;
GO
