/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@IsExportExcel	BIT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
	,@IsIncludeRemovedPlayer BIT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:
		Admin site - Customer - Players Detail
		Admin site - Customer - Statistics - Click amount of Total Active Players

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250506@Sally: Enhance Removed Player logic [RedmineID: #225717]
		- 20250815@Sally: Add date picker functionality [RedmineID: #236120]

	Param's Explanation:
		- @FromDate:	Start date of the range
		- @ToDate:		End date of the range
		- @SortById:	1 = Username
						2 = Registered Date
						3 = Deposit
						4 = Withdrawal
						5 = Turnover
						6 = GGR
						7 = Bonus
					    8 = Rebate
					    9 = Deposit Fee
					   10 = Withdrawal Fee
					   11 = IBCUsername
					   12 = First Deposit Date
					   13 = First Deposit Amount
		- @IsSortAsc:	0 = DESC
						1 = ASC
		- @BaseCurrency : Currency of B2C
		- @Currencies : Currency of B2C, 72: represent for USD( currency 72, 3)

	Example:
		EXEC dbo.Aff_Admin_PlayersDetail_Sel 
			@AffId = 123, 
			@FromDate = '2025-07-15', 
			@ToDate = '2025-08-15',
			@ProductId = 0,
			@PageIndex = 1,
			@PageSize = 20;
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffCurrency INT, @Rate FLOAT
	SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

	--Get AffCurrency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
	SELECT @AffExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @AffCurrency

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	--Get list currencies maping
	DECLARE @ListCurrencies	VARCHAR(MAX) = ''
	SELECT @ListCurrencies = COALESCE(@ListCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
	FROM STRING_SPLIT(@Currencies, ',') f
		CROSS APPLY(
			SELECT TpExchangeId
			FROM dbo.Aff_f_TpExchange_Sel(f.value)
		)t
	
	CREATE TABLE #tmpData (
		CustId INT, 
		Deposit MONEY, 
		Withdrawal MONEY, 
		Turnover MONEY, 
		GGR MONEY, 
		Bonus MONEY, 
		Rebate MONEY,
		DepositFee MONEY,
		WithdrawalFee MONEY
	)

	-- Get list of months within date range (end of month dates)
	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	
	;WITH CTE_MonthDate AS (
		SELECT EOMONTH (@FromDate) AS MonthDate
		UNION ALL
		SELECT DATEADD(MONTH, 1, MonthDate)
		FROM CTE_MonthDate
		WHERE MonthDate <= EOMONTH(DATEADD(MONTH,-1, @ToDate))
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT md.MonthDate
	FROM CTE_MonthDate md
	OPTION (MAXRECURSION 0)

	-- Create temporary table to store deduction settings for each month in date range
	;WITH CTE_DeductionSettings AS (
		SELECT 
			ml.MonthDate,
			SUM(CASE WHEN dsh.DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS DepositRate,
			SUM(CASE WHEN dsh.DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE 0 END) AS DepositAmount,
			SUM(CASE WHEN dsh.DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS WithdrawalRate,
			SUM(CASE WHEN dsh.DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE 0 END) AS WithdrawalAmount
		FROM @MonthDate ml
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON agh.MonthDate = ml.MonthDate AND agh.AffID = @AffId
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId 
																		AND agh.MonthDate = dsh.MonthDate
																		AND dsh.DeductionID IN (13, 14)
		GROUP BY ml.MonthDate
	)
	SELECT 
		ds.MonthDate,
		ds.DepositRate,
		ds.DepositAmount * er.Rate AS DepositAmount,
		ds.WithdrawalRate,
		ds.WithdrawalAmount * er.Rate AS WithdrawalAmount
	INTO #tmpDeductionSettings
	FROM CTE_DeductionSettings ds
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(ds.MonthDate, @AffCurrency, @BaseExchangeId) er						

	DECLARE @Products TABLE (ProductId INT)
	
	-- Get products based on the months in date range
	INSERT INTO @Products (ProductId)
	SELECT p.ProductId
	FROM dbo.Products p WITH (NOLOCK)

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
	
	-- Get data player detail
	BEGIN

		INSERT INTO #tmpData
		(
			CustId
			,Deposit
			,Withdrawal
			,Bonus
			,Rebate
			,Turnover
			,GGR
			,DepositFee
			,WithdrawalFee
		)
		SELECT 
			r.CustId
			,SUM(r.Deposit		* e.Rate)	AS Deposit
			,SUM(r.Withdrawal	* e.Rate)	AS Withdrawal
			,SUM(r.Bonus		* e.Rate)	AS Bonus
			,SUM(r.Rebate		* e.Rate)	AS Rebate
			,SUM(r.Turnover		* e.Rate)	AS Turnover
			,SUM(r.GGR			* e.Rate)	AS GGR
			,SUM(r.Deposit 		* e.Rate * ISNULL(ds.DepositRate, 0) 	+ ISNULL(ds.DepositAmount, 0)) 	  AS DepositFee
			,SUM(r.Withdrawal 	* e.Rate * ISNULL(ds.WithdrawalRate, 0) + ISNULL(ds.WithdrawalAmount, 0)) AS WithdrawalFee
		FROM (
			SELECT EOMONTH(r.winlostDate) AS MonthDate
				,r.CustId
				,r.Currency
				,SUM(ISNULL(r.Deposit, 0))		AS Deposit
				,SUM(ISNULL(r.Withdrawal, 0))	AS Withdrawal
				,SUM(ISNULL(r.Bonus, 0))		AS Bonus
				,SUM(ISNULL(r.Rebate, 0))		AS Rebate
				,SUM(ISNULL(r.Turnover, 0)) 	AS Turnover
				,SUM(ISNULL(-(r.Winloss - ISNULL(ProgressiveWin, 0)) - ISNULL(ProgressiveBet, 0), 0)) AS GGR
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON r.CustId = m.CustId
				LEFT JOIN @Products p ON r.ProductId = p.ProductId
			WHERE r.WinlostDate BETWEEN @FromDate AND @ToDate
				AND r.AffId = @AffId
				AND (m.IsRemoved = 0 OR @IsIncludeRemovedPlayer = 1)
				AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
					WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate 
				)
				AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
			GROUP BY EOMONTH(r.winlostDate), r.CustId, r.Currency
		)r
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
			LEFT JOIN #tmpDeductionSettings ds ON ds.MonthDate = r.MonthDate
		GROUP BY r.CustId	

		DELETE #tmpData WHERE Deposit = 0 AND Withdrawal = 0 AND Bonus = 0 AND Rebate = 0 AND Turnover = 0 AND GGR = 0

		SELECT @NRows = COUNT(1) FROM #tmpData
	END

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
		SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1
	ELSE
		SELECT @RowStart =  1, @RowEnd = @NRows

	SELECT CustId, UserName, IBCUserName, RegisteredDate, FirstDepositDate, FirstDepositAmount, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, DepositFee, WithdrawalFee
	FROM
	(
		SELECT
			m.CustId
			,m.UserName
			,m.IBCUserName
			,m.RegisteredDate
			,m.FirstDepositDate
			,CONVERT(MONEY, m.FirstDepositAmount * ISNULL(e.Rate, 0)) AS FirstDepositAmount
			,d.Deposit
			,d.Withdrawal
			,d.Turnover
			,d.GGR
			,d.Bonus
			,d.Rebate
			,d.DepositFee
			,d.WithdrawalFee
			,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById =  1 THEN m.UserName			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  2 THEN m.RegisteredDate		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  3 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  4 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  5 THEN d.Turnover			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  6 THEN d.GGR				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  7 THEN d.Bonus				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  8 THEN d.Rebate				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  9 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 10 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 11 THEN m.IBCUserName		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 12 THEN m.FirstDepositDate	END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 13 THEN m.FirstDepositAmount * ISNULL(e.Rate, 0)	END) ASC
				
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  1 THEN m.UserName			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  2 THEN m.RegisteredDate		END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  3 THEN d.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  4 THEN d.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  5 THEN d.Turnover			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  6 THEN d.GGR				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  7 THEN d.Bonus				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  8 THEN d.Rebate				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  9 THEN d.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 10 THEN d.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 11 THEN m.IBCUserName		END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 12 THEN m.FirstDepositDate	END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 13 THEN m.FirstDepositAmount * ISNULL(e.Rate, 0)	END) DESC
			) AS RN
		FROM #tmpData d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON m.currency = t.TpExchangeId
			OUTER APPLY dbo.Aff_f_ExchangeRate_Sel(m.FirstDepositDate, ISNULL(t.ExchangeId, m.currency), @BaseExchangeId) e
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN

	DROP TABLE #tmpData
	DROP TABLE #tmpDeductionSettings
END
GO