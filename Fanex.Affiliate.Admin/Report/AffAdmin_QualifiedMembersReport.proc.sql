ALTER PROCEDURE [dbo].[AffAdmin_QualifiedMembersReport] 
	@UserId			INT = 0
	,@AffId			INT
	,@MonthDate		DATETIME
	,@BaseCurrency	TINYINT = 2
AS
/*    
Task : Qualified Members Report  
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
	20140213@Bobbby.Nguyen: Multiply exchange rate

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
		,@AffCurrency INT
		,@SysCurrency INT
		,@SysExRate FLOAT = 1;

	SELECT @Sportsbook = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')
		,@FromDate = dbo.Aff_GetFirstDayOfMonth(@MonthDate)
		,@ToDate = dbo.Aff_GetLastDayOfMonth(@MonthDate)

	SELECT @QualifiedAmount = [dbo].[AffAdmin_QualifiedAmount](@AffId, @MonthDate)

	IF(@BaseCurrency = 1) -- convert QualifiedAmount to SysCurrency
	BEGIN
		SELECT TOP 1 @AffCurrency = Currency
		FROM dbo.AffInfo WITH(NOLOCK)
		WHERE AffID = @AffId

		SELECT TOP 1 @SysCurrency = cur.CurrencyID
		FROM dbo.SystemSettings se WITH(NOLOCK)
		INNER JOIN dbo.Currency cur WITH(NOLOCK)
			ON se.SValue = cur.CurrencyCode
		WHERE SName = 'SystemCurrency'
			AND [Type] = 'Meta'
		
		IF(@AffCurrency <> @SysCurrency)
		BEGIN
			SET @SysExRate = [dbo].[Aff_GetExchangeRate](@AffCurrency, @SysCurrency, null);
		END
	END

	--get exchange rate base on @BaseCurrency
	SELECT m.Username
		,e.Code AS Currency
		,(@QualifiedAmount * @SysExRate) AS QualifiedAmountBase 
		,@QualifiedAmount AS QualifiedAmount --Get from group setting
		
		,Sum(CASE 
				WHEN ProductId = @Sportsbook THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS SportsbookTurnoverBase
		,Sum(CASE 
				WHEN ProductId = @Sportsbook THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS SportsbookTurnover
		,Sum(CASE 
				WHEN ProductId = @NumberGame THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS NumberGameTurnoverBase
		,Sum(CASE 
				WHEN ProductId = @NumberGame THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS NumberGameTurnover
		,Sum(CASE 
				WHEN ProductId = @LiveCasino THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS LiveCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductId = @LiveCasino THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS LiveCasinoTurnover
		,Sum(CASE 
				WHEN ProductId = @RNGCasino THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS RNGCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductId = @RNGCasino THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS RNGCasinoTurnover
	FROM MemberDaily m WITH (NOLOCK)
	INNER JOIN Exchange e WITH (NOLOCK)
		ON m.Currency = e.ExchangeID
	WHERE AffId = @AffID
		AND m.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY m.Username
		,e.Code
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_QualifiedMembersReport] TO [vnteam] AS [dbo]
