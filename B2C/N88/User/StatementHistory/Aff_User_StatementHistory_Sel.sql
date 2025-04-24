/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_StatementHistory_Sel]
	@AffId			INT
	,@BaseCurrency	INT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Statement History

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Include P2P Earning into Monthly Earning [RedmineID: #157958]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
		- 20230130@Malcolm: Correct the total number of output lines [RedmineId: #181455]
		- 20230523@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
		- 20230912@Sally: Fix recursion 100 has been exhausted [RedmineID: #193867]
		- 20240503@Sally: Calculate Revenue Share By Turnover [RedmineID: #203756]
		- 20250418@Sally: Get data BBF by timezone [RedmineID: #222401]

	Param's Explanation:
		- @BaseCurrency : Currency of B2C

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MaxSubLevel SMALLINT, @IsMaxSubLevel BIT = 0
		,@CurrentDate SMALLDATETIME

	SELECT  @MaxSubLevel = CONVERT(SMALLINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'MaxSubLevel'

	SELECT @MaxSubLevel = ISNULL(@MaxSubLevel, 0)
	SELECT @CurrentDate = CONVERT(DATE, DATEADD(HOUR, 12, GETDATE()))

	--Get Base currency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	IF EXISTS (
		SELECT 1
		FROM dbo.AffInfo ai WITH (NOLOCK)
			CROSS APPLY (
				SELECT COUNT(1) AS SubLevel 
				FROM STRING_SPLIT(ai.AllParentAffId, ',') s
			)l
		WHERE ai.AffId = @AffId
			AND l.SubLevel = @MaxSubLevel
	)
		SELECT @IsMaxSubLevel = 1

	CREATE TABLE #tempData
	(
		TransId			BIGINT,
		MonthDate		SMALLDATETIME,
		TransType		INT,
		Amount			MONEY,
		Status			VARCHAR(10),
		Description		NVARCHAR(2000),
		CalculatedType	TINYINT DEFAULT ((2)) -- 0: Current Month, 1: UnCalculated Months, 2: Calculated Months
	)

	-- Payment, Adjustment info (TransType = 202, 203)
	BEGIN
		INSERT INTO #tempData
		(
			TransId,
			MonthDate,
			TransType,
			Amount,
			Status,
			Description
		)
		SELECT
			at.TransId,
			DATEADD(HOUR, 12, at.TransDate) AS MonthDate,
			at.TransType,
			CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END * ISNULL(e.Rate, 1) AS Amount,
			CASE WHEN at.TransType = 202 THEN at.Status ELSE 'B/F' END AS Status,
			CASE at.TransType WHEN 202 THEN ap.AffDesc WHEN 203 THEN '' ELSE at.Description END AS Description
		FROM dbo.AffTrans at WITH (NOLOCK)
			LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID AND at.TransType = 202
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (at.WinlostDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
		WHERE at.AffId = @AffId
			AND at.TransType IN (202, 203)
	END

	-- Commission info
	BEGIN
		DECLARE @MinReportDate SMALLDATETIME
		SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)

		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		-- Calculated months
		IF @MinReportDate <= @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= @MinReportDate
			SELECT @tempToDate		= @MaxCommDate
			
			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFromDate) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempToDate
			)
			INSERT INTO #tempData
			(
				TransId,
				MonthDate,
				TransType,
				Amount,
				Status,
				Description
			)
			SELECT
				0,
				MonthDate,
				TransType,
				SUM(Amount),
				'B/F' AS Status,
				CASE WHEN TransType = 201 THEN 'Monthly Earning' ELSE 'Revenue Share' END AS Description
			FROM (
				SELECT md.MonthDate, CASE WHEN at.TransType = 205 THEN 201 ELSE at.TransType END AS TransType, ISNULL(at.Amount, 0) AS Amount
				FROM CTE_MonthDate md
					OUTER APPLY (
						SELECT at.TransType, at.Amount * e.Rate AS Amount
						FROM dbo.AffTrans at WITH (NOLOCK)
							LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON at.AffCurrency = t.TpExchangeId 
							CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (at.WinlostDate, ISNULL(t.ExchangeId, at.AffCurrency), @BaseExchangeId) e
						WHERE md.MonthDate = at.WinlostDate
							AND at.AffId = @AffId
							AND at.TransType IN (201, 204, 205)
					) at
			) t
			GROUP BY MonthDate, TransType
			OPTION (MAXRECURSION 0)
		END

		-- Uncalculated months
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)
		
		SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
				@tempToDate		= @CurrentDate

		IF @tempFromDate < @MinReportDate
			SELECT @tempFromDate = @MinReportDate

		IF @tempFromDate <= @tempToDate
		BEGIN 
			CREATE TABLE #TempCommission
			(
				MonthDate			SMALLDATETIME,
				AffId				INT,
				GroupId				INT,
				ProductId			INT,
				Deposit				MONEY,
				Withdrawal			MONEY,
				Bonus				MONEY,
				Rebate				MONEY,
				Turnover			MONEY,
				Winloss				MONEY,
				Revenue				MONEY,
				-- Fees
				P2PFee				MONEY,
				PlatFormFee			MONEY,
				OperationalFee		MONEY,
				DepositFee			MONEY,
				WithdrawalFee		MONEY,
				-- Calculation
				GrossWinloss		MONEY,
				NetWinloss			MONEY,
				NetTurnover			MONEY,
				ActivePlayer		INT,
				CommissionRate		FLOAT,
				Commission			MONEY,
				StraightCommission	MONEY,
				SubAffCommission	MONEY,
				IsMultiGroupProduct BIT
			)

			INSERT INTO #TempCommission
			(
				MonthDate,
				AffId,
				GroupId,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Rebate,
				Turnover,
				Winloss,
				Revenue,
				P2PFee,
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
				GrossWinloss,
				NetWinloss,
				NetTurnover,
				ActivePlayer,
				CommissionRate,
				Commission,
				StraightCommission,
				SubAffCommission,
				IsMultiGroupProduct
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1

			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFromDate) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempToDate
			)
			INSERT INTO #tempData
			(
				TransId,
				MonthDate,
				TransType,
				Amount,
				Status,
				Description,
				CalculatedType
			)
			SELECT
				0,
				MonthDate,
				TransType,
				SUM(Amount),
				'Current' AS Status,
				CASE WHEN MonthDate >= @CurrentDate THEN 'Current ' ELSE 'UnCalculated ' END
					+ CASE WHEN TransType = 201 THEN 'Monthly Earning' ELSE 'Revenue Share' END AS Description,
				CASE WHEN MonthDate >= @CurrentDate THEN 0 ELSE 1 END AS CalculatedType
			FROM (
				SELECT md.MonthDate, CASE WHEN at.TransType = 205 THEN 201 ELSE at.TransType END AS TransType, ISNULL(at.Amount, 0) AS Amount
				FROM CTE_MonthDate md
					OUTER APPLY (
						SELECT c.Commission, c.StraightCommission, c.SubAffCommission
						FROM #TempCommission c
						WHERE md.MonthDate = c.MonthDate
							AND c.AffId = @AffId
							AND c.ProductId = 0
					) c
					OUTER APPLY (
						SELECT 201 AS TransType, c.Commission AS Amount
						UNION ALL SELECT 205, c.StraightCommission
						UNION ALL SELECT 204, c.SubAffCommission
					) at
			) t
			GROUP BY MonthDate, TransType
			OPTION (MAXRECURSION 0)

			DROP TABLE #TempCommission
		END
	END

	-- Get GroupType Info
	DECLARE @FromDate DATETIME 
		,@ToDate DATETIME
	SELECT @FromDate = MIN(MonthDate), @ToDate = MAX(MonthDate)
	FROM #tempData

	DECLARE @AffGroupInfo TABLE (MonthDate SMALLDATETIME, GroupTypeName NVARCHAR(100))
	INSERT INTO @AffGroupInfo (MonthDate, GroupTypeName)
	SELECT af.MonthDate
		,af.GroupTypeName
	FROM dbo.Aff_f_AffGroupInfo_Sel(@FromDate, @ToDate, CONVERT(VARCHAR(20), @AffId)) af

	-- Return data
	SELECT @NRows = COUNT(1) FROM #tempData WHERE ISNULL(TransType, 0) <> 204

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		result.MonthDate,
		TransType,
		Amount,
		[Status],
		CASE WHEN result.TransType = 201 AND ISNULL(ag.GroupTypeName, '') <> '' THEN CONCAT(result.[Description],' (',ag.GroupTypeName,')')ELSE  [Description] END AS Description,
		CalculatedType
	FROM
	(
		SELECT
			MonthDate,
			TransType,
			Amount,
			[Status],
			[Description],
			CalculatedType,
			DENSE_RANK() OVER(ORDER BY MonthDate DESC, CASE WHEN TransType IN (201, 204) THEN 0 ELSE TransId END DESC) AS RowNum
		FROM #tempData
	) AS result
		LEFT JOIN @AffGroupInfo ag ON ag.MonthDate = result.MonthDate
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempData
END
GO
