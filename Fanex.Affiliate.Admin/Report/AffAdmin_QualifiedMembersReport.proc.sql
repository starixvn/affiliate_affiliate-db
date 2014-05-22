ALTER PROCEDURE [dbo].[AffAdmin_QualifiedMembersReport] 
	@UserId			INT = 0
	,@AffId			INT
	,@MonthDate		DATETIME
	,@BaseCurrency	TINYINT = 2
	,@ProductIds VARCHAR(100) = NULL
AS
/*    
Task : Qualified Members Report  
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
	- 20140213@Bobbby.Nguyen: Multiply exchange rate
	- 20140514@Bobby: Add Playtech Casio product    

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
		,@PlaytechCasino INT
		,@AffCurrency INT
		,@SysCurrency INT
		,@SysExRate FLOAT = 1;

	SELECT @Sportsbook = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')
		,@PlaytechCasino = dbo.[Aff_GetProductID]('Playtech Casino')
		,@FromDate = dbo.Aff_GetFirstDayOfMonth(@MonthDate)
		,@ToDate = dbo.Aff_GetLastDayOfMonth(@MonthDate)
	
	DECLARE @ProductFilter AS TABLE (ProductId INT)
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
	;WITH QMData AS
	(
		SELECT m.Username
			,e.Code AS Currency
			,(@QualifiedAmount * @SysExRate) AS QualifiedAmountBase 
			,@QualifiedAmount AS QualifiedAmount --Get from group setting
		
			,Sum(CASE 
					WHEN m.ProductId = @Sportsbook THEN Turnover * ISNULL(m.SysExRate, 0)
					ELSE 0
					END) AS SportsbookTurnoverBase
			,Sum(CASE 
					WHEN m.ProductId = @Sportsbook THEN Turnover * ISNULL(m.AffExRate, 0)
					ELSE 0
					END) AS SportsbookTurnover
			,Sum(CASE 
					WHEN m.ProductId = @NumberGame THEN Turnover * ISNULL(m.SysExRate, 0)
					ELSE 0
					END) AS NumberGameTurnoverBase
			,Sum(CASE 
					WHEN m.ProductId = @NumberGame THEN Turnover * ISNULL(m.AffExRate, 0)
					ELSE 0
					END) AS NumberGameTurnover
			,Sum(CASE 
					WHEN m.ProductId = @LiveCasino THEN Turnover * ISNULL(m.SysExRate, 0)
					ELSE 0
					END) AS LiveCasinoTurnoverBase
			,Sum(CASE 
					WHEN m.ProductId = @LiveCasino THEN Turnover * ISNULL(m.AffExRate, 0)
					ELSE 0
					END) AS LiveCasinoTurnover
			,Sum(CASE 
					WHEN m.ProductId = @RNGCasino THEN Turnover * ISNULL(m.SysExRate, 0)
					ELSE 0
					END) AS RNGCasinoTurnoverBase
			,Sum(CASE 
					WHEN m.ProductId = @RNGCasino THEN Turnover * ISNULL(m.AffExRate, 0)
					ELSE 0
					END) AS RNGCasinoTurnover
			,Sum(CASE 
					WHEN m.ProductId = @PlaytechCasino THEN Turnover * ISNULL(m.SysExRate, 0)
					ELSE 0
					END) AS PlaytechCasinoTurnoverBase
			,Sum(CASE 
					WHEN m.ProductId = @PlaytechCasino THEN Turnover * ISNULL(m.AffExRate, 0)
					ELSE 0
					END) AS PlaytechCasinoTurnover
		FROM MemberDaily m WITH (NOLOCK)
			INNER JOIN Exchange e WITH (NOLOCK)
			ON m.Currency = e.ExchangeID
			INNER JOIN @ProductFilter p
			ON m.ProductId = p.ProductId
		WHERE AffId = @AffID
			AND m.WinlostDate BETWEEN @FromDate AND @ToDate
		GROUP BY m.Username
			,e.Code
	)
	SELECT d.* 
	FROM QMData d
	WHERE SportsbookTurnover >= @QualifiedAmount
		OR NumberGameTurnover >= @QualifiedAmount
		OR LiveCasinoTurnover >= @QualifiedAmount
		OR RNGCasinoTurnover >= @QualifiedAmount
		OR PlaytechCasinoTurnover >= @QualifiedAmount
	
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_QualifiedMembersReport] TO [vnteam] AS [dbo]
