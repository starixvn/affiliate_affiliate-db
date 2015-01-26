ALTER PROCEDURE [dbo].[AffAdmin_MemberWinLossReport] 
	@UserId 				INT 			= 0
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
/*  Author:20140827@Bobby.Nguyen
	Task: Member Win Loss Report     
	DB:	DBAFFATHENA000\Affiliate_Athena000 
	Original:[AffAdmin_PlayerWinlossReport]
	Revisions:           
		- 20140827@Bobby: Add Virtual Sport & PlayerComm - apply style-scope
		- 20141112@Bobby: Add more PlayerCurrencyId and AffCurrencyId
                
	Param's Explanation: 
	• @UserId: Admin user id
	• @AffName: Affiliate username
	• @AffTypes: List affilaite type
	• @CommGroups: List Commission group
	• @PreferLanguages: list preference language
	• @GroupBy: by date or month (0: by date; 1: by Member)
	• @FromDate: From date
	• @ToDate: To date
	• @DrawFilter: Bet Count & Turnover filter 
		- 0: "Normal" Betcount and turnover are included
		- 1: "No Draw" The Betcount will be exluded Draw tickets. The turnover will exclude draw & half draw tickets.
		- 2: "No Draw For Turnover Only" The Betcount will be included Draw tickets. The turnover will exclude draw & half draw tickets.
	• @BaseCurrency: The current exchange rate will be used if we wanna convert the affiliate's currency to system currency
		- 0: Original
		- 1: Convert to System Currency.
	• @ExcludeTest: not include test accounts if true.
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun 		DATETIME
		,@endRun 			DATETIME
		,@CurrentDate 		DATETIME
		,@PlaytechCasino 	INT
		,@RptByAff			BIT = 0
		
	DECLARE @ProductFilter 	TABLE (ProductId INT)
	DECLARE @MemCurrencies 	TABLE ( ExchangeId SMALLINT, Currency VARCHAR(10) )
	DECLARE @AffUserRpt 	TABLE (
		AffId 				INT
		,Username 			NVARCHAR(30)
		,AffType 			VARCHAR(50)
		,ExchangeId 		INT
		,Currency 			VARCHAR(5)
		,MonthDate 			DATETIME
		,GroupId 			INT
		,GroupName 			NVARCHAR(100)
	);
	--Reset todate to ending of date
	SELECT @CurrentDate = GETDATE()
		, @FromDate		= CASE WHEN @FromDate IS NULL THEN dbo.Aff_GetFirstDayOfMonth(@CurrentDate) 
								ELSE dbo.Aff_GetStartDate(@FromDate) 
							END
		, @ToDate		= CASE WHEN @ToDate IS NULL OR @ToDate > @CurrentDate THEN @CurrentDate 
							ELSE dbo.Aff_GetEndDate(ISNULL(@ToDate, @CurrentDate)) 
							END
		,@PlayerName 	= '%' + ISNULL(@PlayerName, '') + '%'
		,@startRun		= @CurrentDate

	-- Get productid
	SELECT @PlaytechCasino	= p.ProductID
	FROM dbo.Product p WITH(NOLOCK)
	WHERE p.ProductName = 'Playtech Casino'

	--product filtering
	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT Val
		FROM [dbo].[strSplit_key](@ProductIds, ',')
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT ProductId
		FROM dbo.Product WITH (NOLOCK)
	END

	--currency filtering
	INSERT INTO @MemCurrencies(ExchangeId, Currency)
	SELECT ex.ExchangeId
		,ex.Code
	FROM [dbo].[strSplit](@PlayerCurrencies, ',') tmp
		INNER JOIN dbo.Exchange ex WITH (NOLOCK)
		ON tmp.Val = ex.ExchangeId
	
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
	FROM [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t

	IF( NOT EXISTS(SELECT TOP 1 1 FROM @AffUserRpt))
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not available affiliate user.'
		RETURN;
	END
	ELSE
	BEGIN
		SET @RptByAff = CAST (CASE 
							WHEN LEN(@AffName) > 0 AND (SELECT COUNT(DISTINCT UserName) FROM @AffUserRpt) = 1 THEN 1 
							ELSE @RptByAff 
						END AS BIT)
	END
	
	SELECT 
		CASE WHEN @GroupBy = 0 THEN md.WinlostDate	
				ELSE 0 
			END 							AS WinlostDate
		,md.AffID
		,ai.Username 						AS UserName
		,md.AffCurrency						AS AffCurrencyId
		,ex.Code 							AS Currency
		,md.Username 						AS PlayerUsername
		,md.Currency						AS PlayerCurrencyId
		,mc.Currency 						AS PlayerCurrency
		,CASE WHEN @GroupBy = 0 THEN md.SysExRate 
				ELSE 1
			END 							AS SysExRate
		,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN md.AffExRate 
				ELSE 1
			END 							AS AffExRate
		,ROW_NUMBER() OVER (
			ORDER BY 
					CASE WHEN @GroupBy = 0 THEN md.WinlostDate ELSE 0 END ASC
					,ai.UserName ASC
		) AS RowIDX
	INTO #MemberList
	FROM dbo.MemberDaily md WITH (NOLOCK)
		INNER JOIN @AffUserRpt ai
		ON md.AffID = ai.AffID
			AND DATEDIFF(M, md.WinlostDate, ai.MonthDate) = 0
		INNER JOIN @ProductFilter p
		ON md.ProductID = p.ProductID
		INNER JOIN @MemCurrencies mc
		ON md.Currency = mc.ExchangeId
		INNER JOIN dbo.Exchange ex WITH (NOLOCK)
		ON md.AffCurrency = ex.ExchangeID
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
		,CASE WHEN @GroupBy = 0 THEN md.SysExRate 
				ELSE 1
			END
		,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN md.AffExRate 
				ELSE 1
			END
	HAVING SUM(md.Deposit) 		> 0
		OR SUM(md.Withdrawal) 	<> 0
		OR SUM(md.Winlost) 		<> 0
		OR SUM(md.Bonus) 		> 0
		OR SUM(md.Adjustment)	> 0
		OR SUM(CASE 
				WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
				ELSE ISNULL(md.TurnoverNoDraw, 0)
			END) 				> 0
	
	--set @NRows
	SELECT @NRows = COUNT(DISTINCT rpt.RowIDX)
	FROM #MemberList rpt
	
	IF(@NRows = 0) 
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not available member data.'
		RETURN;
	END
	
	
	SELECT m.RowIDX
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
	----------------------SUMDATA-------------------------------------
		,SUM(ISNULL(md.Deposit, 0)) 		AS Deposit
		,SUM(ISNULL(md.Deposit, 0)
			* md.AffExRate) 				AS Deposit_aff
		,SUM(ISNULL(md.Deposit, 0)
			* md.SysExRate) 				AS DepositBase
		,SUM(ISNULL(md.Withdrawal, 0))		AS Withdrawal
		,SUM(ISNULL(md.Withdrawal, 0)
			* md.AffExRate)					AS Withdrawal_aff
		,SUM(ISNULL(md.Withdrawal, 0)
			* md.SysExRate)					AS WithdrawalBase
		,SUM(ISNULL(md.PSP, 0))				AS PSP
		,SUM(ISNULL(md.PSP, 0)
			* md.AffExRate)					AS PSP_aff
		,SUM(ISNULL(md.PSP, 0)
			* md.SysExRate)					AS PSPBase
		,SUM(ISNULL(md.Bonus, 0))			AS Bonus
		,SUM(ISNULL(md.Bonus, 0)
			* md.AffExRate)					AS Bonus_aff
		,SUM(ISNULL(md.Bonus, 0)
			* md.SysExRate)					AS BonusBase
		,SUM(ISNULL(md.Adjustment, 0))		AS Adjustment
		,SUM(ISNULL(md.Adjustment, 0)
			* md.AffExRate)					AS Adjustment_aff
		,SUM(ISNULL(md.Adjustment, 0)
			* md.SysExRate)					AS AdjustmentBase
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
		INNER JOIN dbo.MemberDaily md WITH (NOLOCK)
		ON m.PlayerUsername = md.Username 
			AND 1 = CASE WHEN @GroupBy = 0 AND m.WinlostDate = md.WinlostDate THEN 1 
						WHEN @GroupBy = 1 THEN 1
						ELSE 0 END
		INNER JOIN @ProductFilter p
		ON md.ProductID = p.ProductID
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
	ORDER BY m.RowIDX ASC
		,m.PlayerUsername ASC
		
	--select sum data - PlayerCurrency
	;WITH memberList AS (
		SELECT PlayerUsername
			,PlayerCurrency
		FROM  #MemberList
		GROUP BY PlayerUsername
			,PlayerCurrency
	)
	SELECT mc.PlayerCurrency
		----------------------SUMDATA-----------------------------------
		,SUM(ISNULL(md.Deposit, 0)) 		AS Deposit
		,SUM(ISNULL(md.Deposit, 0)
			* md.AffExRate) 				AS Deposit_aff
		,SUM(ISNULL(md.Deposit, 0)
			* md.SysExRate) 				AS DepositBase
		,SUM(ISNULL(md.Withdrawal, 0))		AS Withdrawal
		,SUM(ISNULL(md.Withdrawal, 0)
			* md.AffExRate)					AS Withdrawal_aff
		,SUM(ISNULL(md.Withdrawal, 0)
			* md.SysExRate)					AS WithdrawalBase
		,SUM(ISNULL(md.PSP, 0))				AS PSP
		,SUM(ISNULL(md.PSP, 0)
			* md.AffExRate)					AS PSP_aff
		,SUM(ISNULL(md.PSP, 0)
			* md.SysExRate)					AS PSPBase
		,SUM(ISNULL(md.Bonus, 0))			AS Bonus
		,SUM(ISNULL(md.Bonus, 0)
			* md.AffExRate)					AS Bonus_aff
		,SUM(ISNULL(md.Bonus, 0)
			* md.SysExRate)					AS BonusBase
		,SUM(ISNULL(md.Adjustment, 0))		AS Adjustment
		,SUM(ISNULL(md.Adjustment, 0)
			* md.AffExRate)					AS Adjustment_aff
		,SUM(ISNULL(md.Adjustment, 0)
			* md.SysExRate)					AS AdjustmentBase
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
		INNER JOIN memberList mc
		ON md.UserName = mc.PlayerUsername
		INNER JOIN @ProductFilter p
		ON md.ProductID = p.ProductID
	WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY mc.PlayerCurrency
	ORDER BY mc.PlayerCurrency
	
	----------------------SUMTOTAL-----------------------------------
	;WITH memberList AS (
		SELECT PlayerUsername 
		FROM  #MemberList
		GROUP BY PlayerUsername
	)
	SELECT 
		SUM(ISNULL(md.Deposit, 0)
			* md.SysExRate) 				AS DepositBase
		,SUM(ISNULL(md.Withdrawal, 0)
			* md.SysExRate)					AS WithdrawalBase
		,SUM(ISNULL(md.PSP, 0)
			* md.SysExRate)					AS PSPBase
		,SUM(ISNULL(md.Bonus, 0)
			* md.SysExRate)					AS BonusBase
		,SUM(ISNULL(md.Adjustment, 0)
			* md.SysExRate)					AS AdjustmentBase
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
		INNER JOIN memberList m
		ON md.UserName = m.PlayerUsername
		INNER JOIN @ProductFilter p
		ON md.ProductID = p.ProductID
	WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
	
	DROP TABLE #MemberList
	
	SELECT @endRun = GETDATE()
		,@Duration = DATEDIFF(millisecond, @startRun, @endRun)
	
	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_MemberWinLossReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_MemberWinLossReport] TO [vnteam] AS [dbo]

