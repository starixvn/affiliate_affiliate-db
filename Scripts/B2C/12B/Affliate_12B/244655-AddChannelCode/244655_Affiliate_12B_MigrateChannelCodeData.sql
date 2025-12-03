/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251119@Sally
    DB: DBAFF12B-Affiliate_12B
    Task: Migrate ChannelCode data [RedmineID]: #244655 

*/
USE Affiliate_12B;
GO
/*============================================
  . Migrate data ChannelCode by batch 4k
============================================*/
BEGIN
	PRINT 'Building temporary mapping table #CustChannelMap...';
	IF OBJECT_ID('tempdb..#CustChannelMap') IS NOT NULL DROP TABLE #CustChannelMap;
	CREATE TABLE #CustChannelMap (
	  Row_num           INT IDENTITY(1,1) NOT NULL,
	  CustId        BIGINT NOT NULL PRIMARY KEY,
	  ChannelCode   VARCHAR(50) NULL
	);
	INSERT INTO #CustChannelMap (CustId, ChannelCode)
		SELECT mi.CustId, ISNULL(cs.ChannelCode, cbk.ChannelCode) as ChannelCode
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics cs WITH (NOLOCK) ON cs.ClickId = mi.ClickId AND cs.AffId = mi.AffId
			LEFT JOIN dbo.ClickStatistics_bk cbk WITH (NOLOCK) ON cbk.ClickId = mi.ClickId AND cbk.AffId = mi.AffId
		WHERE ISNULL(mi.ClickId, 0) <> 0 AND ISNULL(cs.ChannelCode, cbk.ChannelCode) IS NOT NULL

	INSERT INTO #CustChannelMap (CustId, ChannelCode)
		SELECT mi.CustId, l.ChannelCode AS ChannelCode
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN dbo.AffMediaLink l WITH (NOLOCK) ON mi.AffMediaLinkId = l.AffMediaLinkId AND l.AffId = mi.AffId
		WHERE NOT EXISTS (
			SELECT TOP 1 1
			FROM #CustChannelMap map
			WHERE map.CustId = mi.CustId
		)

	DECLARE @StartRow	INT 
		, @StopRow		INT 
		, @MaxRow		INT	= 0
		, @Threshold	INT  -- the number of each batch
		, @MessageError VARCHAR(50)	= NULL
		, @ErrorCode    INT			= 0

	SET @Threshold = 4000
 
	SELECT @MaxRow = MAX(Row_num) 
	FROM #CustChannelMap

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
		UPDATE mi
		SET mi.ChannelCode = b.ChannelCode
		FROM dbo.MemberInfo mi WITH (UPDLOCK, ROWLOCK)
		INNER JOIN #CustChannelMap b ON b.CustId = mi.CustId
		WHERE b.Row_num BETWEEN @StartRow AND @StopRow

		SET @MessageError = CONVERT(VARCHAR(50), GETDATE(), 121)			
		RAISERROR (@MessageError, 0, 1) WITH NOWAIT
	
		IF @StopRow = @MaxRow BREAK

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @Threshold
		IF @StopRow >= @MaxRow
				SET @StopRow = @MaxRow
	END
	IF (@ErrorCode <> 0)
		PRINT 'Fail Migrate'
	ELSE
		PRINT 'Complete Migrate'

	DROP TABLE IF EXISTS #CustChannelMap
END
GO
