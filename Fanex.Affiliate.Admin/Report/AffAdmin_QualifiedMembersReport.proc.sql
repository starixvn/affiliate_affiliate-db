ALTER PROCEDURE [dbo].[AffAdmin_QualifiedMembersReport] 
	@UserId			INT = 0
	,@AffId			INT
	,@MonthDate		DATETIME
	,@BaseCurrency	TINYINT
AS
/*    
Task : Qualified Members Report  
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
                
Param's Explanation: 
• @UserId: Admin user id
• @AffId: Affiliate ID
• @Month: Month need to view
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @HasPermission BIT

	SELECT @HasPermission = [dbo].[AffAdmin_PermissionOnAffiliate](@UserId, @AffId)

	IF (@HasPermission = 0) RETURN

	-- Get productid
	DECLARE @FromDate DATETIME
		,@ToDate DATETIME
		,@QualifiedAmount MONEY
		,@Sportsbook INT
		,@NumberGame INT
		,@LiveCasino INT
		,@RNGCasino INT

	SELECT @Sportsbook = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')
		,@FromDate = dbo.Aff_GetFirstDayOfMonth(@MonthDate)
		,@ToDate = dbo.Aff_GetLastDayOfMonth(@MonthDate)

	SELECT @QualifiedAmount = [dbo].[AffAdmin_QualifiedAmount](@AffId, @MonthDate)

	--get exchange rate base on @BaseCurrency
	;WITH tmpExRate AS (
	SELECT DISTINCT UserName
		,CASE @BaseCurrency
			WHEN 1 THEN SysExRate
			WHEN 2 THEN AffExRate
			ELSE 1
			END ExRate
		,WinlostDate
	FROM dbo.MemberDaily m WITH (NOLOCK)
	WHERE AffId = @AffID
		AND WinlostDate BETWEEN @FromDate AND @ToDate
	)

	SELECT m.Username
		,e.Code AS Currency
		,@QualifiedAmount AS QualifiedAmount --Get from group setting
		,Sum(CASE 
				WHEN ProductId = @Sportsbook THEN Turnover * ISNULL(ex.ExRate, 1)
				ELSE 0
				END) AS SportsbookTurnover
		,Sum(CASE 
				WHEN ProductId = @NumberGame THEN Turnover * ISNULL(ex.ExRate, 1)
				ELSE 0
				END) AS NumberGameTurnover
		,Sum(CASE 
				WHEN ProductId = @LiveCasino THEN Turnover * ISNULL(ex.ExRate, 1)
				ELSE 0
				END) AS LiveCasinoTurnover
		,Sum(CASE 
				WHEN ProductId = @RNGCasino THEN Turnover * ISNULL(ex.ExRate, 1)
				ELSE 0
				END) AS RNGCasinoTurnover
	FROM MemberDaily m WITH (NOLOCK)
	INNER JOIN Exchange e WITH (NOLOCK)
		ON m.Currency = e.ExchangeID
	LEFT JOIN tmpExRate ex
		ON (m.Username = ex.UserName
			AND m.WinlostDate = ex.WinlostDate)
	WHERE AffId = @AffID
		AND m.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY m.Username
		,e.Code
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_QualifiedMembersReport] TO [vnteam] AS [dbo]
