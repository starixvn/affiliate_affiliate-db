/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@IsExportExcel	BIT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task:
		Admin site - Customer - Players Detail
		Admin site - Customer - Statistics - Click amount of Total Active Players

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
		- 20240222@Sally: Merge VS 1,2,3 into VS only [RedmineID: #199895]

	Param's Explanation:
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
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	--Get list currencies maping
	DECLARE @ListCurrencies	VARCHAR(MAX) = ''
	SELECT @ListCurrencies = COALESCE(@ListCurrencies + ',', '') + CONVERT(VARCHAR(20), t.TpExchangeId)
	FROM string_split(@Currencies, ',') f
		CROSS APPLY(
			SELECT TpExchangeId
			FROM dbo.Aff_f_TpExchange_Sel(f.value)
		)t
	
	CREATE TABLE #tmpData (CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, GGR MONEY, Bonus MONEY, Rebate MONEY)

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
	
	-- Get data
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
		)
		SELECT r.CustId
			,SUM(ISNULL(r.Deposit * e.Rate, 0))		AS Deposit
			,SUM(ISNULL(r.Withdrawal * e.Rate, 0))	AS Withdrawal
			,SUM(ISNULL(r.Bonus * e.Rate, 0))		AS Bonus
			,SUM(ISNULL(r.Rebate * e.Rate, 0))		AS Rebate
			,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate, 0)) AS Turnover
			,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
							ELSE -(r.Winloss - ISNULL(ProgressiveWin, 0)) - ISNULL(ProgressiveBet, 0) END * e.Rate, 0)) AS GGR
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
			LEFT JOIN @Products p ON r.ProductId = p.ProductId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, ISNULL(T.ExchangeId,r.Currency), @BaseExchangeId) e
		WHERE r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
			AND r.AffId = @AffId
			AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
				WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate 
			)
			AND (@ListCurrencies = '' OR ',' + @ListCurrencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
		GROUP BY r.CustId

		DELETE #tmpData WHERE Deposit = 0 AND Withdrawal = 0 AND Bonus = 0 AND Rebate = 0 AND Turnover = 0 AND GGR = 0

		SELECT @NRows = COUNT(1) FROM #tmpData

		-- Banking Fee
		DECLARE @DepositRate DECIMAL(9, 8) = 0, @DepositAmount MONEY = 0
			,@WithdrawalRate DECIMAL(9, 8) = 0, @WithdrawalAmount MONEY = 0
		
		IF EXISTS (SELECT 1 FROM #tmpData WHERE Deposit + Withdrawal > 0)
		BEGIN
			SELECT
				@DepositRate = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @DepositRate END
				,@DepositAmount = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @DepositAmount END
				,@WithdrawalRate = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @WithdrawalRate END
				,@WithdrawalAmount = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @WithdrawalAmount END
			FROM dbo.AffGroupHistory agh WITH (NOLOCK)
				INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
			WHERE dsh.DeductionID IN (13, 14)
				AND agh.MonthDate = @EndOfMonth
				AND agh.AffID = @AffId

			SELECT @DepositRate = ISNULL(@DepositRate, 0), @DepositAmount = ISNULL(@DepositAmount, 0)
				,@WithdrawalRate = ISNULL(@WithdrawalRate, 0), @WithdrawalAmount = ISNULL(@WithdrawalAmount, 0)

			IF @BaseCurrency <> 0
			BEGIN
				DECLARE @AffCurrency INT, @Rate FLOAT
				SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

				--Get AffCurrency mapping
				DECLARE @AffExchangeId INT = @AffCurrency
				SELECT @AffExchangeId = t.ExchangeId
				FROM dbo.TpExchange t WITH (NOLOCK)
				WHERE t.TpExchangeId = @AffCurrency

				SELECT  @Rate = Rate FROM dbo.Aff_f_ExchangeRate_Sel(@EndOfMonth, @AffExchangeId, @BaseExchangeId)
			
				SELECT  @DepositAmount = @DepositAmount * @Rate
						,@WithdrawalAmount = @WithdrawalAmount * @Rate
			END
		END
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
			,d.Deposit * @DepositRate + @DepositAmount AS DepositFee
			,d.Withdrawal * @WithdrawalRate + @WithdrawalAmount AS WithdrawalFee
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
END
GO