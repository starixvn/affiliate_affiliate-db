ALTER PROCEDURE [dbo].[AffAdmin_QualifiedMembersReport] 
	@LicenseeID		INT
	,@UserId			INT
	,@AffId			INT
	,@MonthDate		DATETIME
	,@BaseCurrency	TINYINT 		= 2
	,@ProductIds 	VARCHAR(100)	= NULL
AS
/*    
Task : Qualified Members Report  
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
	- 20140213@Bobbby.Nguyen: Multiply exchange rate
	- 20140514@Bobby: Add Playtech Casio product    
	- 20140523@Bobby: Rollback check QualifiedAmount
	- 20140523@Bobby: Add Virtual Sport & apply style-scope
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site

Param's Explanation: 
• @UserId: Admin user id
• @AffId: Affiliate ID
• @Month: Month need to view
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @HasPermission BIT

	SELECT @HasPermission = [dbo].[AffAdmin_PermissionOnAffiliate](@LicenseeID, @UserId, @AffId)

	IF (@HasPermission = 0) RETURN

	-- Get productid
	DECLARE @FromDate 		DATETIME
		,@ToDate 			DATETIME
		,@QualifiedAmount 	MONEY
		,@Sportsbook 		INT
		,@NumberGame 		INT
		,@LiveCasino 		INT
		,@RNGCasino 		INT
		,@PlaytechCasino 	INT
		,@VirtualSports 		INT
		,@AffCurrency 		INT
		,@SysCurrency 		INT
		,@SysExRate 		FLOAT = 1;

	SELECT @FromDate 		= dbo.Aff_GetFirstDayOfMonth(@MonthDate)
		,@ToDate 			= dbo.Aff_GetLastDayOfMonth(@MonthDate)
		
	-- Get productid
	SELECT @Sportsbook		= CASE WHEN p.ProductName = 'Sportsbook'		THEN p.ProductID ELSE ISNULL(@Sportsbook, 0) END
		, @RNGCasino		= CASE WHEN p.ProductName = 'RNG Casino'		THEN p.ProductID ELSE ISNULL(@RNGCasino, 0) END
		, @NumberGame		= CASE WHEN p.ProductName = 'Number Game'		THEN p.ProductID ELSE ISNULL(@NumberGame, 0) END
		, @LiveCasino		= CASE WHEN p.ProductName = 'Live Casino'		THEN p.ProductID ELSE ISNULL(@LiveCasino, 0) END
		, @PlaytechCasino	= CASE WHEN p.ProductName = 'Playtech Casino'	THEN p.ProductID ELSE ISNULL(@PlaytechCasino, 0) END
		, @VirtualSports	= CASE WHEN p.ProductName = 'Virtual Sports'	THEN p.ProductID ELSE ISNULL(@VirtualSports, 0) END
	FROM dbo.Product p WITH(NOLOCK)
	
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
		SELECT TOP 1 
			@AffCurrency = Currency
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
		,SUM(CASE 
				WHEN m.ProductId = @Sportsbook THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS SportsbookTurnoverBase
		,SUM(CASE 
				WHEN m.ProductId = @Sportsbook THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS SportsbookTurnover
		,SUM(CASE 
				WHEN m.ProductId = @NumberGame THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS NumberGameTurnoverBase
		,SUM(CASE 
				WHEN m.ProductId = @NumberGame THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS NumberGameTurnover
		,SUM(CASE 
				WHEN m.ProductId = @LiveCasino THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS LiveCasinoTurnoverBase
		,SUM(CASE 
				WHEN m.ProductId = @LiveCasino THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS LiveCasinoTurnover
		,SUM(CASE 
				WHEN m.ProductId = @RNGCasino THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS RNGCasinoTurnoverBase
		,SUM(CASE 
				WHEN m.ProductId = @RNGCasino THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS RNGCasinoTurnover
		,SUM(CASE 
				WHEN m.ProductId = @PlaytechCasino THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS PlaytechCasinoTurnoverBase
		,SUM(CASE 
				WHEN m.ProductId = @PlaytechCasino THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS PlaytechCasinoTurnover
		,SUM(CASE 
				WHEN m.ProductId = @VirtualSports THEN Turnover * ISNULL(m.SysExRate, 0)
				ELSE 0
				END) AS VirtualSportsTurnoverBase
		,SUM(CASE 
				WHEN m.ProductId = @VirtualSports THEN Turnover * ISNULL(m.AffExRate, 0)
				ELSE 0
				END) AS VirtualSportsTurnover
	FROM dbo.MemberDaily m WITH (NOLOCK)
		INNER JOIN dbo.Exchange e WITH (NOLOCK)
		ON m.Currency = e.ExchangeID
		INNER JOIN @ProductFilter p
		ON m.ProductId = p.ProductId
	WHERE AffId = @AffID
		AND m.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY m.Username
		,e.Code
	
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [olympus] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_QualifiedMembersReport] TO [vnteam] AS [dbo]