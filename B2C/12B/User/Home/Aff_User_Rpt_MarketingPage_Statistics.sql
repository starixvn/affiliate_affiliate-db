/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Rpt_MarketingPage_Statistics]
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
*/

BEGIN
	SET NOCOUNT ON
    DECLARE @CutOffDate SMALLDATETIME
    SELECT @CutOffDate = dbo.Aff_f_GetSetting('MKTStatisticsRpt_ClickId_CutOffDate')  --  This day is 2025-03-31, After this day we will use new formula on ClickStatistics.ClickId

	SELECT  @FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate)
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME 

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate =  dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics')

	CREATE TABLE #tmpData (AffMediaLink VARCHAR(500), LanguageCode VARCHAR(10), ChannelCode VARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT)
	CREATE CLUSTERED INDEX CIX_tmpData ON #tmpData (AffMediaLink)
	
	CREATE TABLE #tmp_Result (ChannelName NVARCHAR(200),LanguageCode VARCHAR(10), AffMediaLink VARCHAR(500), MarketName NVARCHAR(50), ChannelCode VARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT, IsShow BIT)
	
	IF @ToDate > @ArchiveDate
	BEGIN
 
		SELECT  @FDate = CASE WHEN @FromDate > @ArchiveDate THEN @FromDate ELSE DATEADD(Day,1,@ArchiveDate) END 
				,@TDate = DATEADD(Day,1,@ToDate)

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode,ChannelCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, ChannelCode

		-- Signups, FDM --
		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, SignUps, FDM)
		SELECT
			c.AffMediaLink, c.LanguageCode, c.ChannelCode,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics c WITH (NOLOCK) ON c.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
					(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
					)
		GROUP BY
			c.AffMediaLink, c.LanguageCode, c.ChannelCode
		-- End Signups, FDM -- 
	END

	IF @FromDate <= @ArchiveDate
	BEGIN 
		SELECT  @FDate = @FromDate 
				,@TDate = CASE WHEN @ToDate > @ArchiveDate THEN DATEADD(Day,1,@ArchiveDate) ELSE DATEADD(Day,1,@ToDate) END

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, ChannelCode
		
		-- ClickStatistics_bk
		BEGIN
			SELECT @FDate = CASE WHEN @FromDate <= @CutOffDate THEN DATEADD(Day,1,@CutOffDate) ELSE @FromDate END
				,@TDate = CASE WHEN @ToDate > @ArchiveDate THEN DATEADD(Day,1,@ArchiveDate) ELSE DATEADD(Day,1,@ToDate) END
			
			-- Signups, FDM --
			INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, SignUps, FDM)
			SELECT
				c.AffMediaLink, c.LanguageCode, c.ChannelCode,
				COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
				COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
			FROM dbo.MemberInfo mi WITH (NOLOCK)
				LEFT JOIN dbo.ClickStatistics_bk c WITH (NOLOCK) ON c.clickId = mi.clickId
			WHERE mi.AffId = @AffID
				AND (
						(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
						OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
						)
			GROUP BY
				c.AffMediaLink, c.LanguageCode, c.ChannelCode
			-- End Signups, FDM --
		END
		
		---- AffMediaLink
		IF @FromDate <= @CutOffDate 
		BEGIN 
			SELECT @FDate = @FromDate 
				,@TDate = CASE WHEN @ToDate > @CutOffDate THEN DATEADD(Day,1,@CutOffDate) ELSE DATEADD(Day,1,@ToDate) END
			
			;WITH CTE_MemberInfo AS (  
			SELECT ISNULL(m.AffMediaLinkId, 0) AS AffMediaLinkId  
				,COUNT(1)AS SignUps   
				,0 AS FDM
			FROM dbo.MemberInfo m WITH (NOLOCK)  
			WHERE AffId = @AffId    
				AND RegisteredDate >= @FDate 
				AND RegisteredDate < @TDate 
			GROUP BY ISNULL(m.AffMediaLinkId, 0)  
			UNION ALL
			SELECT ISNULL(m.AffMediaLinkId, 0) AS AffMediaLinkId  
				,0 AS SignUps
				,COUNT(1)AS FDM  
			FROM dbo.MemberInfo m WITH (NOLOCK)  
			WHERE AffId = @AffId    
				AND FirstDepositDate >= @FDate 
				AND FirstDepositDate < @TDate 
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