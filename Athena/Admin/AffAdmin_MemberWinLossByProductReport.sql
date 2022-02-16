/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_MemberWinLossByProductReport] 
	@UserCurrencies 	VARCHAR(MAX)	= ''
	,@AffName 				NVARCHAR(100) 	= NULL
	,@AffTypes 				VARCHAR(100) 	= NULL
	,@CommGroups 			VARCHAR(1000) 	= NULL
	,@PreferLanguages 		VARCHAR(1000) 	= NULL
	,@PlayerName 			NVARCHAR(100) 	= NULL
	,@GroupBy 				TINYINT 		= 0
	,@FromDate 				DATETIME 		= NULL
	,@ToDate 				DATETIME 		= NULL
	,@PlayerCurrencies 		VARCHAR(100) 	= NULL
	,@BaseCurrency 			TINYINT 		= 0
	,@DrawFilter 			TINYINT 		= 0
	,@ExcludeTest 			BIT 			= 1
	,@IsITAdmin 			BIT 			= 0
	,@PageCurrent 			INT 			= 1
	,@PageSize 				INT 			= 25
	,@ProductIds 			VARCHAR(100) 	= NULL
	,@NRows 				INT 			= 0 	OUTPUT
	,@Error 				INT 			= 0 	OUTPUT
	,@Error_Msg 			NVARCHAR(100) 	= '' 	OUTPUT
	,@Duration 				INT 			= 0 	OUTPUT
AS

/*
	Author:20140827@Bobby.Nguyen
	Task: Member Win Loss Report     
	DB:	DBAFF.Affiliate_Athena000 
	Original:[AffAdmin_MemberWinLossReport]
	
	Revisions:           
		- 20140827@Bobby: Add Virtual Sport & PlayerComm - apply style-scope
		- 20141112@Bobby: Add more PlayerCurrencyId and AffCurrencyId
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170607@Percy: Fixing total row [RedmineID: #77859]
		- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get list of currencies [RedmineID: #90545]
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]
                
	Param's Explanation: 
		� @UserId: Admin user id
		� @AffName: Affiliate username
		� @AffTypes: List affilaite type
		� @CommGroups: List Commission group
		� @PreferLanguages: list preference language
		� @GroupBy: by date or month (0: by date; 1: by Member)
		� @FromDate: From date
		� @ToDate: To date
		� @DrawFilter: Bet Count & Turnover filter 
			- 0: "Normal" Betcount and turnover are included
			- 1: "No Draw" The Betcount will be exluded Draw tickets. The turnover will exclude draw & half draw tickets.
			- 2: "No Draw For Turnover Only" The Betcount will be included Draw tickets. The turnover will exclude draw & half draw tickets.
		� @BaseCurrency: The current exchange rate will be used if we wanna convert the affiliate's currency to system currency
			- 0: Original
			- 1: Convert to System Currency.
		� @ExcludeTest: not include test accounts if true.
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @startRun 		DATETIME
		,@endRun 			DATETIME
		,@CurrentDate 		DATETIME
		,@PlaytechCasino 	INT
		,@RptByAff			BIT = 0
		
	DECLARE @ProductFilter 	TABLE (GroupProductId INT, ProductId INT, GroupProductName VARCHAR(100))
	DECLARE @MemCurrencies 	TABLE (ExchangeId SMALLINT, Currency VARCHAR(10))
	DECLARE @AffUserRpt 	TABLE
	(
		AffId 				INT
		,Username 			NVARCHAR(30)
		,AffType 			VARCHAR(50)
		,ExchangeId 		INT
		,Currency 			VARCHAR(5)
		,MonthDate 			DATETIME
		,GroupId 			INT
		,GroupName 			NVARCHAR(100)
	)
	
	--Reset todate to ending of date
	SELECT @CurrentDate = GETDATE()
		,@FromDate		= CASE WHEN @FromDate IS NULL THEN dbo.Aff_GetFirstDayOfMonth(@CurrentDate) ELSE dbo.Aff_GetStartDate(@FromDate) END
		,@ToDate		= CASE WHEN @ToDate IS NULL OR @ToDate > @CurrentDate THEN @CurrentDate ELSE dbo.Aff_GetEndDate(ISNULL(@ToDate, @CurrentDate)) END
		,@PlayerName 	= '%' + ISNULL(@PlayerName, '') + '%'
		,@startRun		= @CurrentDate

	-- Get productid
	SELECT @PlaytechCasino	= p.ProductID
	FROM dbo.Product p WITH(NOLOCK)
	WHERE p.ProductName = 'Playtech Casino'

	--product filtering
	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (GroupProductId, ProductId, GroupProductName)
		SELECT ISNULL(g.GroupProductId, p.ProductId), ISNULL(g.ProductId, p.ProductId), ISNULL(g.GroupProductName, p.ProductName)
		FROM [dbo].[strSplit](@ProductIds, ',') s
			INNER JOIN dbo.Product p WITH (NOLOCK) ON s.val = p.ProductId
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON p.ProductId = g.GroupProductId
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (GroupProductId, ProductId, GroupProductName)
		SELECT ISNULL(g.GroupProductId, p.ProductId), ISNULL(g.ProductId, p.ProductId), ISNULL(g.GroupProductName, p.ProductName)
		FROM dbo.Product p WITH (NOLOCK)
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON p.ProductId = g.ProductId
	END

	--currency filtering
	INSERT INTO @MemCurrencies(ExchangeId, Currency)
	SELECT ex.ExchangeId
		,ex.Code
	FROM [dbo].[strSplit](@PlayerCurrencies, ',') tmp
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON tmp.Val = ex.ExchangeId
	
	-- affiliate user filterring
	INSERT INTO @AffUserRpt
	SELECT AffId
		,Username
		,AffType
		,ExchangeId
		,Currency
		,MonthDate
		,GroupId
		,GroupName
	FROM [dbo].[AffAdmin_AffiliateListForReport](@UserCurrencies, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t

	IF( NOT EXISTS(SELECT TOP 1 1 FROM @AffUserRpt))
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not available affiliate user.'
		RETURN;
	END
	ELSE
	BEGIN
		SET @RptByAff = CASE WHEN LEN(@AffName) > 0 AND (SELECT COUNT(DISTINCT UserName) FROM @AffUserRpt) = 1 THEN CONVERT(BIT, 1) ELSE @RptByAff END
	END
	
	SELECT 
		CASE WHEN @GroupBy = 0 THEN md.WinlostDate ELSE 0 END AS WinlostDate
		,md.AffID
		,ai.Username 						AS UserName
		,md.AffCurrency						AS AffCurrencyId
		,ex.Code 							AS Currency
		,md.Username 						AS PlayerUsername
		,md.Currency 						AS PlayerCurrencyId
		,mc.Currency 						AS PlayerCurrency
		,CASE WHEN @GroupBy = 0 THEN md.SysExRate ELSE 1 END AS SysExRate
		,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN md.AffExRate ELSE 1 END AS AffExRate
		,ROW_NUMBER() OVER (ORDER BY CASE WHEN @GroupBy = 0 THEN md.WinlostDate ELSE 0 END ASC, ai.UserName ASC) AS RowIDX
	INTO #MemberList
	FROM dbo.MemberDaily md WITH (NOLOCK)
		INNER JOIN @AffUserRpt ai ON md.AffID = ai.AffID AND DATEDIFF(M, md.WinlostDate, ai.MonthDate) = 0
		INNER JOIN @ProductFilter p ON md.ProductID = p.ProductID
		INNER JOIN @MemCurrencies mc ON md.Currency = mc.ExchangeId
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON md.AffCurrency = ex.ExchangeID
	WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
		AND md.UserName LIKE @PlayerName
	GROUP BY 
		CASE WHEN @GroupBy = 0 THEN md.WinlostDate	ELSE 0 END
		,md.AffID
		,ai.Username
		,md.AffCurrency	
		,ex.Code
		,md.Username
		,md.Currency 
		,mc.Currency
		,CASE WHEN @GroupBy = 0 THEN md.SysExRate ELSE 1 END
		,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN md.AffExRate ELSE 1 END
	HAVING SUM(md.Winlost) <> 0
		OR SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0) ELSE ISNULL(md.TurnoverNoDraw, 0) END) > 0
	
	--set @NRows
	SELECT @NRows = COUNT(DISTINCT RowIDX) FROM #MemberList
	
	IF(@NRows = 0) 
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not available member data.'
		RETURN;
	END
	
	SELECT 
		m.RowIDX
		,m.WinlostDate
		,m.AffID
		,m.UserName
		,m.AffCurrencyId
		,m.Currency
		,m.PlayerUsername
		,m.PlayerCurrencyId
		,m.PlayerCurrency
		,m.SysExRate AS ExRate
		,m.AffExRate
		,p.GroupProductId AS ProductId
		,p.GroupProductName AS ProductName
	----------------------SUMDATA-------------------------------------
		,SUM(CASE WHEN @DrawFilter = 1 THEN ISNULL(md.BetCountNoDraw, 0)
					ELSE ISNULL(md.BetCount, 0)
			END)							AS BetCount
		
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END)						AS TotalTurnover
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END
			* md.AffExRate)					AS TotalTurnover_aff
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END
			* md.SysExRate)					AS TotalTurnoverBase
		,SUM(ISNULL(md.PlayerComm, 0))		AS PlayerComm
		,SUM(ISNULL(md.PlayerComm, 0)
			* md.AffExRate)					AS PlayerComm_aff
		,SUM(ISNULL(md.PlayerComm, 0)
			* md.SysExRate)					AS PlayerCommBase
		,SUM(ISNULL(md.Winlost, 0))			AS MemberWinLoss
		,SUM(ISNULL(md.Winlost, 0)
			* md.AffExRate)					AS MemberWinLoss_Aff
		,SUM(ISNULL(md.Winlost, 0)
			* md.SysExRate)					AS MemberWinLossBase
		----------------------PWin,PShare & NetGmaing----------------------
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END) 							AS PWin
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END * md.AffExRate)				AS PWin_aff
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END * md.SysExRate)				AS PWinBase
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END) 							AS PShare
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END * md.AffExRate)				AS PShare_aff
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END * md.SysExRate)				AS PShareBase
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END) AS NetGaming
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END * md.AffExRate) 			AS NetGaming_aff
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END * md.SysExRate) 			AS NetGamingBase
	FROM #MemberList m
		INNER JOIN dbo.MemberDaily md WITH (NOLOCK) ON m.PlayerUsername = md.Username
			AND 1 = CASE WHEN @GroupBy = 0 AND m.WinlostDate = md.WinlostDate THEN 1 WHEN @GroupBy = 1 THEN 1 ELSE 0 END
		INNER JOIN @ProductFilter p ON md.ProductID = p.ProductID
	WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
		AND m.RowIDX BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
	GROUP BY 
		m.RowIDX
		,m.WinlostDate
		,m.AffID
		,m.UserName
		,m.AffCurrencyId
		,m.Currency
		,m.PlayerUsername
		,m.PlayerCurrencyId
		,m.PlayerCurrency
		,m.SysExRate
		,m.AffExRate
		,p.GroupProductId
		,p.GroupProductName
	ORDER BY m.RowIDX 		ASC
		,m.PlayerUsername 	ASC		
		,p.GroupProductId 	ASC
	
	--select sum data - PlayerCurrency + Product
	;WITH memberList AS (
		SELECT PlayerUsername
			,PlayerCurrency
			,WinlostDate
		FROM  #MemberList
		GROUP BY PlayerUsername
			,PlayerCurrency
			,WinlostDate
	)
	SELECT mc.PlayerCurrency
		,p.GroupProductId AS ProductId
		,p.GroupProductName AS ProductName
	----------------------SUMDATA-----------------------------------
		,SUM(CASE WHEN @DrawFilter = 1 THEN ISNULL(md.BetCountNoDraw, 0)
					ELSE ISNULL(md.BetCount, 0)
			END)							AS BetCount
		
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END)						AS TotalTurnover
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END
			* md.AffExRate)					AS TotalTurnover_aff
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END
			* md.SysExRate)					AS TotalTurnoverBase
		,SUM(ISNULL(md.PlayerComm, 0))		AS PlayerComm
		,SUM(ISNULL(md.PlayerComm, 0)
			* md.AffExRate)					AS PlayerComm_aff
		,SUM(ISNULL(md.PlayerComm, 0)
			* md.SysExRate)					AS PlayerCommBase
		,SUM(ISNULL(md.Winlost, 0))			AS MemberWinLoss
		,SUM(ISNULL(md.Winlost, 0)
			* md.AffExRate)					AS MemberWinLoss_Aff
		,SUM(ISNULL(md.Winlost, 0)
			* md.SysExRate)					AS MemberWinLossBase
		----------------------PWin,PShare & NetGmaing----------------------
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END) 							AS PWin
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END * md.AffExRate)				AS PWin_aff
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END * md.SysExRate)				AS PWinBase
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END) 							AS PShare
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END * md.AffExRate)				AS PShare_aff
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END * md.SysExRate)				AS PShareBase
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END) AS NetGaming
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END * md.AffExRate) 			AS NetGaming_aff
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END * md.SysExRate) 			AS NetGamingBase
	FROM dbo.MemberDaily md WITH (NOLOCK)
		INNER JOIN memberList mc ON md.UserName = mc.PlayerUsername
			AND 1 = CASE WHEN @GroupBy = 0 AND mc.WinlostDate = md.WinlostDate THEN 1 WHEN @GroupBy = 1 THEN 1 ELSE 0 END
		INNER JOIN @ProductFilter p ON md.ProductID = p.ProductID
	WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY mc.PlayerCurrency
		,p.GroupProductId
		,p.GroupProductName
	ORDER BY mc.PlayerCurrency 	ASC
		,p.GroupProductId 		ASC
		
	
	----------------------SUMTOTAL By PRODUCT-----------------------------------
	;WITH memberList AS (
		SELECT PlayerUsername, WinlostDate
		FROM  #MemberList
		GROUP BY PlayerUsername, WinlostDate
	)
	SELECT 
		p.GroupProductId AS ProductId
		,p.GroupProductName AS ProductName
		,SUM(CASE WHEN @DrawFilter = 1 THEN ISNULL(md.BetCountNoDraw, 0)
					ELSE ISNULL(md.BetCount, 0)
			END)							AS BetCount
		,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
					ELSE ISNULL(md.TurnoverNoDraw, 0)
				END
			* md.SysExRate)					AS TotalTurnoverBase
		,SUM(ISNULL(md.PlayerComm, 0)
			* md.SysExRate)					AS PlayerCommBase
		,SUM(ISNULL(md.Winlost, 0)
			* md.SysExRate)					AS MemberWinLossBase
		----------------------PWin,PShare & NetGmaing----------------------
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
				ELSE 0 
			END * md.SysExRate)				AS PWinBase
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
				ELSE 0 
			END * md.SysExRate)				AS PShareBase
		,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
				ELSE 0
			END * md.SysExRate) 			AS NetGamingBase
	FROM dbo.MemberDaily md WITH (NOLOCK)
		INNER JOIN memberList m ON md.UserName = m.PlayerUsername
			AND 1 = CASE WHEN @GroupBy = 0 AND m.WinlostDate = md.WinlostDate THEN 1 WHEN @GroupBy = 1 THEN 1 ELSE 0 END
		INNER JOIN @ProductFilter p ON md.ProductID = p.ProductID
	WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY p.GroupProductId
		,p.GroupProductName
	ORDER BY p.GroupProductId ASC
		
	DROP TABLE #MemberList
	
	SELECT @endRun = GETDATE()
		,@Duration = DATEDIFF(millisecond, @startRun, @endRun)
END
GO