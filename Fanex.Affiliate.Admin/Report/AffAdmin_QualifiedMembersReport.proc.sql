USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_QualifiedMembersReport] 
	@LicenseeID		INT
	,@UserId			INT
	,@AffId			INT
	,@MonthDate		DATETIME
	,@BaseCurrency	TINYINT 		= 2
	,@ProductIds 	VARCHAR(100)	= NULL
AS

/*    
	Task: Qualified Members Report  
	DB: DBAFF.Affiliate_Athena000
	Original: [AffAdmin_CommissionReport]

	Revisions:           
		- 20140213@Bobby.Nguyen: Multiply exchange rate
		- 20140514@Bobby: Add Playtech Casio product    
		- 20140523@Bobby: Rollback check QualifiedAmount
		- 20140523@Bobby: Add Virtual Sport & apply style-scope
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20151119@Bobby: Do update for listing product dynamically

	Param's Explanation: 
		• @UserId: Admin user id
		• @AffId: Affiliate ID
		• @Month: Month need to view
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @HasPermission BIT
	SELECT  @HasPermission = [dbo].[AffAdmin_PermissionOnAffiliate] (@LicenseeID, @UserId, @AffId)

	IF (@HasPermission = 0) RETURN
	
	-- Get productid
	DECLARE @FromDate 		DATETIME
		,@ToDate 			DATETIME
		,@QualifiedAmount 	MONEY
		,@AffCurrency 		INT
		,@SysCurrency 		INT
		,@SysExRate 		FLOAT = 1

	SELECT @FromDate 		= dbo.Aff_GetFirstDayOfMonth(@MonthDate)
		,@ToDate 			= dbo.Aff_GetLastDayOfMonth(@MonthDate)
		
		
	DECLARE @ProductFilter TABLE (ProductId INT)
	
	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT CONVERT(INT, val)
		FROM [dbo].[strSplit] (@ProductIds, ',')
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
			INNER JOIN dbo.Currency cur WITH(NOLOCK) ON se.SValue = cur.CurrencyCode
		WHERE SName = 'SystemCurrency'
			AND [Type] = 'Meta'
		
		IF(@AffCurrency <> @SysCurrency)
		BEGIN
			SET @SysExRate = [dbo].[Aff_GetExchangeRate](@AffCurrency, @SysCurrency, NULL)
		END
	END

	--get exchange rate base on @BaseCurrency
	SELECT m.Username
		,e.Code AS Currency
		,(@QualifiedAmount * @SysExRate) AS QualifiedAmountBase 
		,@QualifiedAmount AS QualifiedAmount --Get from group setting
		, m.ProductId
		, p.ProductName
		,SUM(ISNULL(Turnover,0) * ISNULL(m.SysExRate, 0)) AS TurnoverBase
		,SUM(ISNULL(Turnover,0) * ISNULL(m.AffExRate, 0)) AS Turnover
	FROM dbo.MemberDaily m WITH (NOLOCK)
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON m.Currency = e.ExchangeID
		INNER JOIN @ProductFilter pt ON m.ProductId = pt.ProductId
		INNER JOIN dbo.Product p ON pt.ProductId = p.ProductId
	WHERE AffId = @AffID
		AND m.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY m.Username
		, e.Code
		, m.ProductId
		, p.ProductName
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_QualifiedMembersReport] TO [vnteam] AS [dbo]
GO