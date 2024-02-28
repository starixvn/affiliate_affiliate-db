/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task:
		User site - Statement History - Daily Earning
		Admin site - Customer - Statement History - Daily Earning

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Show WL = 0 for P2P Products [RedmineID: #157958]
		- 20210916@Percy: Change WL to GGR [RedmineID: #161540]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]
		- 20230522@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
		- 20240206@Sally: Merge VS 1,2,3 into VS only [RedmineID: #199895]

	Param's Explanation:
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)

*/

BEGIN
	SET NOCOUNT ON
	
	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

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
			,Bonus		MONEY
			,Rebate		MONEY
		)

		INSERT INTO #Data (WinlostDate, Deposit, Withdrawal, Bonus, Rebate, GGR)
		SELECT r.WinlostDate
			,SUM(ISNULL(r.Deposit * e.Rate, 0))		AS Deposit
			,SUM(ISNULL(r.Withdrawal * e.Rate, 0))	AS Withdrawal
			,SUM(ISNULL(r.Bonus * e.Rate, 0))		AS Bonus
			,SUM(ISNULL(r.Rebate * e.Rate, 0))		AS Rebate
			,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
			LEFT JOIN @Products p ON r.ProductId = p.ProductId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		WHERE r.AffId = @AffId
			AND r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
			AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY r.WinlostDate
	END
	
	-- Return data
	BEGIN
		-- Detail
		SELECT WinlostDate, Deposit, Withdrawal, GGR, Bonus, Rebate
		FROM #Data
		ORDER BY WinlostDate

		-- Sum
		SELECT
			SUM(Deposit)		AS Deposit
			,SUM(Withdrawal)	AS Withdrawal
			,SUM(GGR)			AS GGR
			,SUM(Bonus)			AS Bonus
			,SUM(Rebate)		AS Rebate
		FROM #Data
	END

	DROP TABLE #Data
END
GO