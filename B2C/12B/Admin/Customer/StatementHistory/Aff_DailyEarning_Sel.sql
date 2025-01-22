/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_DailyEarning_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:
		User site - Statement History - Daily Earning
		Admin site - Customer - Statement History - Daily Earning

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

	Param's Explanation:
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsFilterCurrencies BIT = 0
		,@ListCurrencies VARCHAR(MAX) = ''

	--Get list currencies mapping
	IF(ISNULL(@Currencies, '') <> '')
	BEGIN
		SET @IsFilterCurrencies = 1
		SELECT @ListCurrencies = COALESCE(@ListCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
		FROM STRING_SPLIT(@Currencies, ',') f
			CROSS APPLY(
				SELECT TpExchangeId
				FROM dbo.Aff_f_TpExchange_Sel(f.value)
			)t
	END

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= EOMONTH(@BeginOfMonth)

	-- Get Data
	BEGIN
		DECLARE @Products TABLE (ProductId INT, IsStraightSetting BIT)
		
		INSERT INTO @Products (ProductId, IsStraightSetting)
		SELECT DISTINCT dsh.ProductId, 0
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
		WHERE dsh.ProductId > 0
			AND agh.MonthDate = @EndOfMonth
			AND agh.AffID = @AffId

		INSERT INTO @Products (ProductId, IsStraightSetting)
		SELECT DISTINCT ssh.ProductId, 1
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
		WHERE ssh.ProductId > 0
			AND agh.MonthDate = @EndOfMonth
			AND agh.AffID = @AffId
		
		IF @ProductId <> 0
		BEGIN
			;WITH CTE_GProducts AS(
				SELECT CONVERT(INT,f.Value) AS ProductId
				FROM STRING_SPLIT(dbo.Aff_f_AddRelatedProducts(CONVERT(VARCHAR(10),@ProductId)), ',')f
			)
			DELETE p
			FROM @Products p
				LEFT JOIN CTE_GProducts gp ON gp.ProductId = p.ProductId
			WHERE gp.ProductId IS NULL
		END

		CREATE TABLE #Data
		(
			WinlostDate SMALLDATETIME
			,Deposit	MONEY
			,Withdrawal	MONEY
			,GGR		MONEY
			,Turnover	MONEY
			,Bonus		MONEY
			,Rebate		MONEY
		)

		INSERT INTO #Data (WinlostDate, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR)
		SELECT r.WinlostDate
			,SUM(ISNULL(r.Deposit * e.Rate, 0))		AS Deposit
			,SUM(ISNULL(r.Withdrawal * e.Rate, 0))	AS Withdrawal
			,SUM(ISNULL(r.Bonus * e.Rate, 0))		AS Bonus
			,SUM(ISNULL(r.Rebate * e.Rate, 0))		AS Rebate
			,SUM(ISNULL(r.Turnover * e.Rate, 0))	AS Turnover
			,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
			LEFT JOIN @Products p ON r.ProductId = p.ProductId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		WHERE r.AffId = @AffId
			AND r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
			AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
			AND (@IsFilterCurrencies = 0 
				OR (',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%' )
			)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY r.WinlostDate
	END
	
	-- Return data
	BEGIN
		-- Detail
		SELECT WinlostDate, Deposit, Withdrawal, GGR, Turnover, Bonus, Rebate
		FROM #Data
		ORDER BY WinlostDate

		-- Sum
		SELECT
			SUM(Deposit)		AS Deposit
			,SUM(Withdrawal)	AS Withdrawal
			,SUM(GGR)			AS GGR
			,SUM(Turnover)		AS Turnover
			,SUM(Bonus)			AS Bonus
			,SUM(Rebate)		AS Rebate
		FROM #Data
	END

	DROP TABLE #Data
END
GO