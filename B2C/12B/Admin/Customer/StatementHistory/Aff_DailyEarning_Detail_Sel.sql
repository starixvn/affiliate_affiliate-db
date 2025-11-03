/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
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
		User site - Statement History - Daily Earning - Detail
		Admin site - Customer - Statement History - Daily Earning - Detail

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20251002@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for recent data based on commission date boundary [RedmineID: #239737]

	Param's Explanation:
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)
		
	Notes:
	  - MemberInfo dates are DateTime in GMT+8
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for Deposit data after commission boundary
	  - Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = EOMONTH(@MonthDate)

	-- Get commission date boundary for data separation
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, CONVERT(SMALLDATETIME, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @MonthDate))
	SELECT @WinlostDateTo = DATEADD(DAY, 1, CONVERT(DATE, @MonthDate))

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	--List list currencies maping
	DECLARE @ListCurrencies	VARCHAR(MAX) = ''
	SELECT @ListCurrencies = COALESCE(@ListCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
	FROM STRING_SPLIT(@Currencies, ',') f
		CROSS APPLY(
			SELECT TpExchangeId
			FROM dbo.Aff_f_TpExchange_Sel(f.value)
		)t

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

		-- Get data using conditional approach based on commission date
		IF @MonthDate < @CommissionBoundary
		BEGIN
			-- Historical data only from rptMemberDaily (for dates before commission boundary)
			SELECT mi.CustId, mi.UserName, mi.IBCUsername, r.Deposit, r.Withdrawal, r.Turnover, r.GGR, r.Bonus, r.Rebate
			FROM (
				SELECT r.CustId
					,SUM(ISNULL(r.Deposit * e.Rate, 0))		AS Deposit
					,SUM(ISNULL(r.Withdrawal * e.Rate, 0))	AS Withdrawal
					,SUM(ISNULL(r.Bonus * e.Rate, 0))		AS Bonus
					,SUM(ISNULL(r.Rebate * e.Rate, 0))		AS Rebate
					,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate, 0)) AS Turnover
					,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
				WHERE r.AffId = @AffId
					AND r.WinlostDate = @MonthDate
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
					AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
				GROUP BY r.CustId
			) r
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON r.CustId = mi.CustId
		END
		ELSE
		BEGIN
			-- Hybrid approach: Use DepositInfo for Deposit only, and rptMemberDaily for other data
			;WITH CTE_RptData AS(
				-- Data from rptMemberDaily (exclude Deposit, include other data normally)
				SELECT r.CustId
					,0 AS Deposit  -- No deposits from rptMemberDaily in hybrid approach
					,SUM(ISNULL(r.Withdrawal * e.Rate, 0)) AS Withdrawal
					,SUM(ISNULL(r.Bonus * e.Rate, 0)) AS Bonus
					,SUM(ISNULL(r.Rebate * e.Rate, 0)) AS Rebate
					,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate, 0)) AS Turnover
					,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
				WHERE r.AffId = @AffId
					AND r.WinlostDate = @MonthDate
					AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
					AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
				GROUP BY r.CustId
			),
			CTE_DepositData AS(
				-- Deposit data from live DepositInfo only
				SELECT d.CustId
					,SUM((d.ActualDeposit * 1.0 / CASE WHEN er.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) * er.Rate) AS Deposit
					,0 AS Withdrawal  -- No withdrawals from DepositInfo
					,0 AS Bonus       -- No bonuses from DepositInfo
					,0 AS Rebate      -- No rebates from DepositInfo
					,0 AS Turnover    -- No turnover from DepositInfo
					,0 AS GGR         -- No GGR from DepositInfo
				FROM bodb_12B.dbo.DepositInfo d WITH(NOLOCK)
					INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON d.CustId = mi.CustId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@MonthDate, ISNULL(t.ExchangeId, mi.Currency), @BaseExchangeId) er
				WHERE mi.AffId = @AffId
					AND d.Status = 3  -- Approved deposits only
					AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index first
					AND CONVERT(DATE, DATEADD(HOUR, 8, d.CreateTime)) = CONVERT(DATE, @MonthDate)  -- Convert GMT+0 to GMT+8
					AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), mi.Currency) + ',%')
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = d.CustId 
						AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate  -- Convert to GMT+8 for comparison
					)
				GROUP BY d.CustId
			),
			CTE_CombinedData AS (
				-- Combine both data sources using UNION ALL and aggregate
				SELECT 
					CustId,
					SUM(Deposit) AS Deposit,
					SUM(Withdrawal) AS Withdrawal,
					SUM(Turnover) AS Turnover,
					SUM(GGR) AS GGR,
					SUM(Bonus) AS Bonus,
					SUM(Rebate) AS Rebate
				FROM (
					SELECT CustId, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR FROM CTE_RptData
					UNION ALL
					SELECT CustId, Deposit, Withdrawal, Bonus, Rebate, Turnover, GGR FROM CTE_DepositData
				) combined
				GROUP BY CustId
			)
			SELECT mi.CustId, mi.UserName, mi.IBCUsername
				,c.Deposit
				,c.Withdrawal
				,c.Turnover
				,c.GGR
				,c.Bonus
				,c.Rebate
			FROM CTE_CombinedData c
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON c.CustId = mi.CustId
			WHERE mi.AffId = @AffId;
		END
	END
END
GO