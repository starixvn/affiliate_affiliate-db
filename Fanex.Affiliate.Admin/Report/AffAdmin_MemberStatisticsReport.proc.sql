/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_MemberStatisticsReport] 
	@UserCurrencies 	VARCHAR(MAX)	= ''
	,@AffName			NVARCHAR(100) = NULL
	,@AffTypes			VARCHAR(100) = NULL
	,@PreferLanguages	VARCHAR(1000) = NULL
	,@Currencies		VARCHAR(100) = NULL
	,@GroupBy			TINYINT = 0
	,@FromDate			SMALLDATETIME = NULL
	,@ToDate			SMALLDATETIME = NULL
	,@SortBy			TINYINT = 0
	,@ExcludeTest		BIT = 1
	,@IsITAdmin			BIT = 0
AS

/*      
	Task : Player Winloss Report       
	DB:      
	Original:[[AffAdmin_MemberStatisticsReport]]  
	Revisions:             
		- 20140509:Bobby: update UniqueClick by date
		- 20140509:Bobby: update ActiveMember by date
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get list of currencies [RedmineID: #90545]

	Param's Explanation:   
	• @UserId: Admin user id  
	• @AffName: Affiliate username  
	• @AffTypes: List affilaite type  
	--• @CommGroups: List Commission group  
	• @PreferLanguages: list preference language  
	• @Currencies: List currencies  
	• @GroupBy: by date or month (0: by All; 1: by Date; 2: By Month)  
	• @FromDate: From date  
	• @ToDate: To date  
	• @SortBy:   
	 - 0: Affiliate  
	 - 1: Sign Up  
	 - 2: Active  
	• @ExcludeTest: not include test accounts if true.  
	• @@IsITAdmin: Is IT Account.  
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @AffList AS TABLE (
		AffId INT
		,Username VARCHAR(50)
		,AffType VARCHAR(50)
		,LANGUAGE NVARCHAR(255)
		,Currency VARCHAR(5)
		,STATUS VARCHAR(50)
		)

	INSERT INTO @AffList (
		AffId
		,Username
		,AffType
		,LANGUAGE
		,Currency
		,STATUS
		)
	SELECT AffId
		,Username
		,AffType
		,LANGUAGE
		,Currency
		,STATUS
	FROM [dbo].[AffAdmin_AffiliateListForReport](@UserCurrencies, @AffName, @AffTypes, NULL, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate)

	DECLARE @clickStats AS TABLE (
		AffId INT
		,DateClick DATETIME
		,TotalClick INT
		,UniqueClick INT
		,Signups INT
		,FDM INT
		)
	DECLARE @Result AS TABLE (
		AffId INT
		,Username VARCHAR(50)
		,DateClick DATETIME
		,AffType VARCHAR(50)
		,LANGUAGE NVARCHAR(255)
		,Currency VARCHAR(5)
		,STATUS VARCHAR(50)
		,TotalClick INT
		,UniqueClick INT
		,Signups INT
		,FDM INT
		)

	SELECT @LastDateSum = (
			SELECT MAX(DATE)
			FROM ClickStatisticsSum
			)

	SELECT @LastDateSum = ISNULL(@LastDateSum, dateadd(d, - 1, @FromDate))
		,@FromDate = [dbo].[Aff_GetStartDate](@FromDate)

	IF (@GroupBy = 0) --Reset from date from system start and Current date (All data)  
	BEGIN
		SELECT @FromDate = cast((
					SELECT TOP (1) SValue
					FROM SystemSettings(NOLOCK)
					WHERE Type = 'Meta'
						AND SName = 'SystemStartDate'
					) AS SMALLDATETIME)
			,@ToDate = current_timestamp
	END


	-- member stats into
	SELECT m.clickId
		,SUM(CASE 
				WHEN m.RegisteredDate IS NOT NULL THEN 1
				ELSE 0
				END) AS Signups
		,SUM(CASE 
				WHEN m.CreatedDate IS NOT NULL THEN 1
				ELSE 0
				END) AS FDM
	INTO #memStatsInfo
	FROM MemberInfo m WITH (NOLOCK)
		INNER JOIN @AffList ai
		ON m.AffId = ai.AffId
	WHERE RegisteredDate BETWEEN @FromDate AND @ToDate
		OR CreatedDate BETWEEN @FromDate AND @ToDate
	GROUP BY ClickID

	IF (@LastDateSum < @FromDate) --get from main table  
	BEGIN
		INSERT INTO @clickStats
		SELECT c.AffId
			,c.DATE AS DateClick
			,SUM(ClickCount) AS TotalClick
			,COUNT(DISTINCT IP) AS UniqueClick
			,SUM(m.Signups) AS Signups
			,SUM(m.FDM) AS FDM
		FROM ClickStatistics c(NOLOCK)
			INNER JOIN @AffList ai
			ON c.AffId = ai.AffId
			LEFT JOIN #memStatsInfo m
			ON c.ClickId = m.ClickId
		WHERE [Date] BETWEEN @FromDate AND @ToDate
		GROUP BY c.AffId
			,c.[date]
			,IP
	END
	ELSE IF (@LastDateSum > @ToDate) --get from summary table  
	BEGIN
		INSERT INTO @clickStats
		SELECT c.AffId
			,c.DATE AS DateClick
			,SUM(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(TotalSignup) AS Signups
			,SUM(TotalDeposit) AS FDM
		FROM ClickStatisticsSum c(NOLOCK)
			INNER JOIN @AffList ai
			ON c.AffId = ai.AffId
		WHERE [Date] BETWEEN @FromDate AND @ToDate
		GROUP BY c.AffId
			,c.[date]
	END
	ELSE --@fromdate < @LastDateSum < @ToDate  
	BEGIN
		INSERT INTO @clickStats
		SELECT AffId
			, DateClick
			, TotalClick
			, UniqueClick
			, Signups
			, FDM
		FROM (
			SELECT c.AffId
				,c.DATE AS DateClick
				,SUM(ClickCount) AS TotalClick
				,COUNT(DISTINCT IP) AS UniqueClick
				,SUM(m.Signups) AS Signups
				,SUM(m.FDM) AS FDM
			FROM ClickStatistics c(NOLOCK)
				INNER JOIN @AffList ai
				ON c.AffId = ai.AffId
				LEFT JOIN #memStatsInfo m
				ON c.ClickId = m.ClickId
			WHERE [Date] BETWEEN @FromDate AND @ToDate
			GROUP BY c.AffId
				,c.[date]
				,IP

			UNION 
			SELECT c.AffId
				,c.DATE AS DateClick
				,SUM(TotalClick) AS TotalClick
				,SUM(UniqueClick) AS UniqueClick
				,SUM(TotalSignup) AS Signups
				,SUM(TotalDeposit) AS FDM
			FROM ClickStatisticsSum c WITH(NOLOCK)
				INNER JOIN @AffList ai
				ON c.AffId = ai.AffId
			WHERE [Date] BETWEEN @FromDate AND @ToDate
			GROUP BY c.AffId
				,c.[date]
		) AS T
	END

	INSERT INTO @Result
	SELECT t.AffId
		,Username
		,ck.DateClick
		,AffType
		,LANGUAGE
		,Currency
		,t.STATUS
		,SUM(ck.TotalClick) AS TotalClick
		,SUM(ck.UniqueClick) AS UniqueClick
		,SUM(ISNULL(Signups, 0)) AS Signups
		,SUM(ISNULL(FDM, 0)) AS FDM
	FROM @AffList AS t
		LEFT JOIN @clickStats ck
		ON t.AffId = ck.AffID
	GROUP BY t.AffId
		,Username
		,DateClick
		,AffType
		,LANGUAGE
		,Currency
		,t.STATUS

	IF (@GroupBy = 0) -- By All (Affiliate)  
	BEGIN
		SELECT r.*
			,tmp.ActivePlayers
		FROM (
			SELECT r.AffId
				,Username
				,AffType
				,LANGUAGE
				,Currency
				,STATUS
				,SUM(TotalClick) AS TotalClick
				,SUM(UniqueClick) AS UniqueClick
				,SUM(Signups) AS Signups
				,SUM(FDM) AS FDM
				,SUM(Signups - FDM) AS NonDeposit
			FROM @Result AS r
			GROUP BY r.AffId
				,Username
				,AffType
				,LANGUAGE
				,Currency
				,STATUS
			) r
			LEFT JOIN (
				SELECT md.AffId
					,COUNT(DISTINCT md.UserName) AS ActivePlayers
				FROM MemberDaily md WITH (NOLOCK)
				INNER JOIN @AffList ai 
				ON md.AffId = ai.AffId
				INNER JOIN MemberInfo mi WITH (NOLOCK)
				ON md.UserName = mi.UserName
				WHERE md.Turnover > 0
				AND AffAffectedDate <= md.Winlostdate
				GROUP BY md.AffID
			) AS tmp
			ON r.AffId = tmp.AffId
		WHERE TotalClick > 0
			OR UniqueClick > 0
			OR Signups > 0
			OR FDM > 0
			OR tmp.ActivePlayers > 0
		ORDER BY (CASE 
				WHEN @SortBy = 1 THEN Signups
				WHEN @SortBy = 2 THEN ActivePlayers END
				) DESC
			,r.AffId
	END
	ELSE IF (@GroupBy = 1) -- By Date  
	BEGIN
		WITH activePlayer
		AS (
			SELECT md.AffID
				,COUNT(DISTINCT md.UserName) AS ActivePlayers
				,WinlostDate
			FROM MemberDaily md WITH (NOLOCK)
				INNER JOIN @AffList ai 
				ON md.AffId = ai.AffId
				INNER JOIN MemberInfo mi WITH (NOLOCK)
				ON md.UserName = mi.UserName
			WHERE md.Winlostdate BETWEEN @FromDate AND @ToDate
				AND md.Turnover > 0
				AND AffAffectedDate <= md.Winlostdate
			GROUP BY md.AffID
				,Winlostdate
		)
		, rptDate
		AS (
			SELECT AffId 
				, WinlostDate AS DateClick
			FROM activePlayer

			UNION
			SELECT AffId, DateClick
			FROM @Result
		)
		SELECT rpt.AffId
			,rpt.DateClick
			,ai.Username
			,ai.AffType
			,ai.[LANGUAGE]
			,ai.Currency
			,ai.[STATUS]
			,ISNULL(ck.TotalClick, 0) TotalClick
			,ISNULL(ck.UniqueClick, 0) UniqueClick
			,ISNULL(ck.Signups, 0) Signups
			,ISNULL(ck.FDM, 0) FDM
			,ISNULL(ck.NonDeposit, 0) NonDeposit
			,ISNULL(at.ActivePlayers, 0) ActivePlayers
		FROM rptDate rpt
		LEFT JOIN @AffList ai ON rpt.AffId = ai.AffId
		LEFT JOIN (
			SELECT r.AffId
				,DateClick
				,SUM(TotalClick) AS TotalClick
				,SUM(UniqueClick) AS UniqueClick
				,SUM(Signups) AS Signups
				,SUM(FDM) AS FDM
				,SUM(Signups - FDM) AS NonDeposit
			FROM @Result AS r
			GROUP BY r.AffId
				,DateClick
			) ck
			ON rpt.AffId = ck.AffId AND rpt.DateClick = ck.DateClick
			LEFT JOIN activePlayer at ON rpt.AffId = at.AffId AND rpt.DateClick = at.WinlostDate
		WHERE ck.TotalClick > 0
			OR ck.UniqueClick > 0
			OR ck.Signups > 0
			OR ck.FDM > 0
			OR at.ActivePlayers > 0
		ORDER BY (CASE 
				WHEN @SortBy = 1 THEN Signups
				WHEN @SortBy = 2 THEN ActivePlayers END
				) DESC
			,(CASE 
				WHEN @SortBy = 3 THEN rpt.AffId END
				)
			,DateClick DESC
			,Username
	END
	ELSE IF (@GroupBy = 2) -- By Month  
	BEGIN
		WITH activePlayer
		AS (
			SELECT md.AffID
				,COUNT(DISTINCT md.UserName) AS ActivePlayers
				,dateadd(m, datediff(m, 0, Winlostdate), 0) AS WinlostDate
			FROM MemberDaily md WITH (NOLOCK)
				INNER JOIN @AffList ai 
				ON md.AffId = ai.AffId
				INNER JOIN MemberInfo mi WITH (NOLOCK)
				ON md.UserName = mi.UserName
			WHERE md.Winlostdate BETWEEN @FromDate AND @ToDate
				AND md.Turnover > 0
				AND AffAffectedDate <= md.Winlostdate
			GROUP BY md.AffID
				,dateadd(m, datediff(m, 0, Winlostdate), 0)
		), rptMonth AS
		(
			SELECT AffID, WinlostDate AS DateClick 
			FROM activePlayer
			
			UNION
			SELECT AffId, dateadd(m, datediff(m, 0, r.DateClick), 0) AS DateClick
			FROM @Result r
		)
		SELECT rpt.AffId
			,rpt.DateClick
			,ai.Username
			,ai.AffType
			,ai.LANGUAGE
			,ai.Currency
			,ai.STATUS
			,ISNULL(r.TotalClick, 0) AS TotalClick
			,ISNULL(r.UniqueClick, 0) AS UniqueClick
			,ISNULL(r.Signups, 0) AS Signups
			,ISNULL(r.FDM, 0) AS FDM
			,ISNULL(NonDeposit, 0) AS NonDeposit
			,ISNULL(tmp.ActivePlayers, 0) AS ActivePlayers
		FROM rptMonth rpt
		INNER JOIN @AffList ai
		ON rpt.AffID = ai.AffId
		LEFT JOIN (
		SELECT r.AffId
			,dateadd(m, datediff(m, 0, r.DateClick), 0) AS DateClick
			,SUM(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(Signups) AS Signups
			,SUM(FDM) AS FDM
			,SUM(Signups - FDM) AS NonDeposit
		FROM @Result AS r
		GROUP BY r.AffId
			,dateadd(m, datediff(m, 0, r.DateClick), 0)
		) AS r
		ON rpt.AffID = r.AffId AND rpt.DateClick = r.DateClick
		LEFT JOIN activePlayer tmp
		ON rpt.AffId = tmp.AffId AND rpt.DateClick = tmp.WinlostDate
	WHERE TotalClick > 0
		OR UniqueClick > 0
		OR Signups > 0
		OR FDM > 0
		OR tmp.ActivePlayers > 0
	ORDER BY (CASE 
			WHEN @SortBy = 1 THEN Signups
			WHEN @SortBy = 2 THEN tmp.ActivePlayers END
			) DESC
		,(CASE 
			WHEN @SortBy = 3 THEN r.AffId END
			)
		,(CASE 
			WHEN r.DateClick IS NULL THEN tmp.WinlostDate
			ELSE r.DateClick END
			) DESC
		,ai.Username
	END

	DROP TABLE #memStatsInfo
END
GO