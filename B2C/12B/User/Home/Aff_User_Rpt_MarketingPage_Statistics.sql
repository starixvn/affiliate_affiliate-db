/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Rpt_MarketingPage_Statistics]
	@AffId				INT
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@LanguageCodes		VARCHAR(MAX) = ''
	,@IncludedInActive	BIT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Statistics - Marketing Page Statistics

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
        - 20250221@Sally: Enhance AFFMediaLink [RedmineID: #212201]
		- 20250305@Sally: Enhance get AFFMediaLinkId [RedmineID: #212201]
		- 20250402@Sophia: Fix date, remove GroupBy Date for UniqueClick[RedmineID: #222777]
		- 20250403@Sophia: Get Signup by ClickID [RedmineID: #222929]
		- 20250408@Sophia: Add ChannelCode into ClickStatistics [Redmine: #222765]
		- 20250416@Sophia: Get report by timezone [RedmineID: #222352]
		- 20250505@Sophia: Fix Signups duplicated data [RedmineID: #226056]
		
	Param:
		@FromDate: GMT+8, Date only
		@ToDate: GMT+8, Date only
		
	Notes:
	  - ClickStatistics.Date contains Date only, in GMT-4
	  - ClickStatistics.UpdatedTime is DateTime in GMT-4
	  - MemberInfo dates are DateTime in GMT+8
	  - @ArchiveDate is in GMT-4, the maximum date in ClickStatistics_bk
*/

BEGIN
	SET NOCOUNT ON
    DECLARE @CutOffDate SMALLDATETIME
    SELECT @CutOffDate = dbo.Aff_f_GetSetting('MKTStatisticsRpt_ClickId_CutOffDate')  -- This day is 2025-03-31

	-- Normalize date parameters to start/end of day
	SELECT @FromDate = CONVERT(DATE, @FromDate)
	SELECT @ToDate = CONVERT(DATE, DATEADD(DAY, 1, @ToDate))

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics') -- GMT-4, Date only
	
	-- Convert from GMT+8 to GMT-4 for date comparison with ClickStatistics.Date
	DECLARE @FromDate_GMT4 DATETIME, @ToDate_GMT4 DATETIME
	SELECT @FromDate_GMT4 = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)), -- GMT+8 to GMT-4
	       @ToDate_GMT4 =  DATEADD(HOUR, -12, CAST(@ToDate AS DATETIME)) -- GMT+8 to GMT-4

	DECLARE @TmpFromDate SMALLDATETIME, @TmpToDate SMALLDATETIME

	CREATE TABLE #tmpData (AffMediaLink VARCHAR(500), LanguageCode VARCHAR(10), ChannelCode VARCHAR(50), TotalClick INT DEFAULT(0), UniqueClick INT DEFAULT(0), SignUps INT DEFAULT(0), FDM INT DEFAULT(0))
	CREATE CLUSTERED INDEX CIX_tmpData ON #tmpData (AffMediaLink)
	
	CREATE TABLE #tmp_Result (ChannelName NVARCHAR(200),LanguageCode VARCHAR(10), AffMediaLink VARCHAR(500), MarketName NVARCHAR(50), ChannelCode VARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT, IsShow BIT)
	
	-- Signups, FDM using MemberInfo (in GMT+8)
	INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, SignUps, FDM)
	SELECT
		COALESCE(md.AffMediaLink, bk.AffMediaLink, '') as AffMediaLink, 
		COALESCE(md.LanguageCode, bk.LanguageCode, '') as LanguageCode,
		COALESCE(md.ChannelCode, bk.ChannelCode, '') as ChannelCode,
		COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
		COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickId = mi.clickId
		LEFT JOIN dbo.ClickStatistics_bk bk WITH (NOLOCK) ON bk.clickId = mi.clickId
	WHERE mi.AffId = @AffID
		AND (
				(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
				OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
			)
	GROUP BY
		COALESCE(md.AffMediaLink, bk.AffMediaLink, ''),
		COALESCE(md.LanguageCode, bk.LanguageCode, ''), 
		COALESCE(md.ChannelCode, bk.ChannelCode, '')
	
	
	IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate -- For current data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for click data
		SELECT @TmpFromDate = CASE WHEN CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate THEN CONVERT(DATE, @FromDate_GMT4) ELSE DATEADD(Day, 1, @ArchiveDate) END,
		       @TmpToDate = DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4))

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use full datetime in GMT-4
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, ChannelCode

		 
	END

	IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate -- For archived data
	BEGIN 			
		-- Calculate date ranges in GMT-4 timezone for archived click data
		SELECT @TmpFromDate = CONVERT(DATE, @FromDate_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate THEN DATEADD(Day, 1, @ArchiveDate) ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use full datetime in GMT-4
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, ChannelCode
		
		-- Signups, FDM from archived data using MemberInfo (in GMT+8)
		DECLARE @OldFromDate DATETIME  
		DECLARE @OldToDate DATETIME 
			
		/*BEGIN

			 

			IF CONVERT (DATE,@ToDate_GMT4) > @CutoffDate AND CONVERT (DATE,@FromDate_GMT4) < @ArchiveDate
			BEGIN 
				-- Get dates after CutOffDate
				SELECT @OldFromDate = CASE WHEN CONVERT(DATE, @FromDate_GMT4 ) <= @CutOffDate THEN DATEADD(HOUR, 12, DATEADD(Day,1,@CutOffDate)) ELSE @FromDate END,
					@OldToDate = CASE WHEN CONVERT (DATE,@ToDate_GMT4) >= @ArchiveDate THEN DATEADD(HOUR, 12, DATEADD(Day,1,@ArchiveDate)) ELSE @ToDate END
				
				INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, SignUps, FDM)
				SELECT
					c.AffMediaLink, c.LanguageCode, c.ChannelCode,
					COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
					COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
				FROM dbo.MemberInfo mi WITH (NOLOCK)
					LEFT JOIN dbo.ClickStatistics_bk c WITH (NOLOCK) ON c.clickId = mi.clickId
				WHERE mi.AffId = @AffID
					AND (
							(mi.RegisteredDate >= @OldFromDate AND mi.RegisteredDate < @OldToDate)	 
							OR (mi.FirstDepositDate >= @OldFromDate AND mi.FirstDepositDate < @OldToDate)
						)
				GROUP BY
					c.AffMediaLink, c.LanguageCode, c.ChannelCode
			END
		END
		*/
		
		-- AffMediaLink handling for older data,  Get dates before CutOffDate
		IF CONVERT (DATE,@FromDate_GMT4) <= @CutOffDate 
		BEGIN 
			SELECT @OldFromDate = @FromDate
			SELECT @OldToDate = CASE WHEN CONVERT (DATE,@ToDate_GMT4) > @CutOffDate THEN DATEADD(HOUR, 12, DATEADD(Day,1,@CutOffDate)) ELSE DATEADD(Day,1,@ToDate) END
			
			;WITH CTE_MemberInfo AS (  
			SELECT ISNULL(m.AffMediaLinkId, 0) AS AffMediaLinkId  
				,COUNT(1)AS SignUps   
				,0 AS FDM
			FROM dbo.MemberInfo m WITH (NOLOCK)  
			WHERE AffId = @AffId    
				AND RegisteredDate >= @OldFromDate 
				AND RegisteredDate < @OldToDate 
			GROUP BY ISNULL(m.AffMediaLinkId, 0)  
			UNION ALL
			SELECT ISNULL(m.AffMediaLinkId, 0) AS AffMediaLinkId  
				,0 AS SignUps
				,COUNT(1)AS FDM  
			FROM dbo.MemberInfo m WITH (NOLOCK)  
			WHERE AffId = @AffId    
				AND FirstDepositDate >= @OldFromDate 
				AND FirstDepositDate < @OldToDate 
			GROUP BY ISNULL(m.AffMediaLinkId, 0)  
			) ,
			CTE_SigupsData AS(
				SELECT AffMediaLinkId, SUM(SignUps) as SignUps, SUM(FDM)AS FDM  
				FROM CTE_MemberInfo
				GROUP BY AffMediaLinkId
			)
			INSERT INTO #tmp_Result (ChannelName, AffMediaLink, MarketName, SignUps, FDM, IsShow)
				SELECT CASE WHEN ISNULL(c.ChannelName, '') ='' THEN 'Others' ELSE c.ChannelName END AS ChannelName
					,l.AffMediaLink
					,m.MarketName
					,SUM(s.SignUps) AS SignUps
					,SUM(s.FDM) AS FDM
					,ISNULL(l.IsShow,1) AS IsShow
				FROM CTE_SigupsData  s
					LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON s.AffMediaLinkId = l.AffMediaLinkId AND l.AffId = @AffId
					LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON l.ChannelCode = c.ChannelCode AND c.AffId = @AffId
					LEFT JOIN dbo.Market m WITH (NOLOCK) ON l.LanguageCode = m.MarketId
				WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')
				GROUP BY CASE WHEN ISNULL(c.ChannelName, '') ='' THEN 'Others' ELSE c.ChannelName END 
					,l.AffMediaLink
					,m.MarketName
					,ISNULL(l.IsShow,1)		
		END
		
	END

	;WITH CTE_Result AS (
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick, SUM(SignUps) AS SignUps, SUM(FDM) AS FDM
		FROM #tmpData
		GROUP BY AffMediaLink, LanguageCode, ChannelCode
	)
	INSERT INTO #tmp_Result (ChannelName, AffMediaLink, MarketName, TotalClick, UniqueClick, SignUps, FDM, IsShow)
	SELECT
		CASE WHEN ISNULL(c.ChannelName, '') ='' THEN 'Others' ELSE c.ChannelName END AS ChannelName
		,r.AffMediaLink
		,m.MarketName
		,r.TotalClick
		,r.UniqueClick
		,r.SignUps
		,r.FDM
		,ISNULL(l.IsShow,1)	
	FROM CTE_Result r
		LEFT JOIN dbo.Market m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
		LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON r.ChannelCode = c.ChannelCode AND c.AffId = @AffId	
		LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON r.AffMediaLink = l.AffMediaLink AND l.AffId = @AffId and M.MarketId = l.LanguageCode
	WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')
		
	IF @IncludedInActive = 0
		DELETE #tmp_Result WHERE IsShow = 0
		

	SELECT ChannelName, AffMediaLink, MarketName
		,SUM(ISNULL(TotalClick,0)) AS TotalClick 
		,SUM(ISNULL(UniqueClick,0)) AS UniqueClick
		,SUM(ISNULL(SignUps,0)) AS SignUps
		,SUM(ISNULL(FDM,0)) AS FDM
	FROM #tmp_Result
	GROUP BY ChannelName, AffMediaLink, MarketName

	DROP TABLE #tmpData
	DROP TABLE #tmp_Result
END
GO