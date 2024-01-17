/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_StatementHistory_Sel] 
	@AffId		INT,
	@FDate		SMALLDATETIME = NULL,
	@TDate		SMALLDATETIME = NULL,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Customer - Statement History

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)

	IF @FDate IS NULL OR @TDate IS NULL
		SELECT @FDate = @MinReportDate, @TDate = CONVERT(DATE, GETDATE())
	ELSE
	BEGIN
		SELECT @FDate = CONVERT(DATE, @FDate), @TDate = CONVERT(DATE, @TDate)
		
		IF @FDate < @MinReportDate
			SELECT @FDate = @MinReportDate
	END

	IF @FDate > @TDate
		RETURN

	CREATE TABLE #tempData
	(
		TransId			BIGINT,
		MonthDate		SMALLDATETIME,
		TransType		INT,
		Amount			MONEY,
		Status			VARCHAR(10),
		Creator			NVARCHAR(50),
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
			Creator,
			Description
		)
		SELECT
			at.TransId,
			at.TransDate,
			at.TransType,
			CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount,
			CASE WHEN at.TransType = 202 THEN at.Status ELSE 'B/F' END AS Status,
			ISNULL(au.Username, 'System') AS Creator,
			CASE WHEN at.TransType = 202 THEN ap.AdminDesc ELSE at.Description END AS Description
		FROM dbo.AffTrans at WITH (NOLOCK)
			LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID AND at.TransType = 202
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON at.Creator = au.custid
		WHERE at.AffId = @AffId
			AND at.TransType IN (202, 203)
			AND at.TransDate >= @FDate AND at.TransDate < DATEADD(DAY, 1, @TDate)
	END

	-- Commission info
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		-- Calculated months
		IF @FDate <= @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= @FDate
			SELECT @tempToDate		= CASE WHEN @TDate > @MaxCommDate THEN @MaxCommDate ELSE @TDate END
			
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
				Creator,
				Description
			)
			SELECT
				0,
				MonthDate,
				TransType,
				SUM(Amount),
				'B/F' AS Status,
				'System' AS Creator,
				CASE WHEN TransType = 201 THEN 'Monthly Earning' ELSE 'Revenue Share' END AS Description
			FROM (
				SELECT md.MonthDate, CASE WHEN at.TransType = 205 THEN 201 ELSE at.TransType END AS TransType, ISNULL(at.Amount, 0) AS Amount
				FROM CTE_MonthDate md
					OUTER APPLY (
						SELECT at.TransType, at.Amount
						FROM dbo.AffTrans at WITH (NOLOCK)
						WHERE md.MonthDate = at.TransDate
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

		IF @TDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= CASE WHEN @FDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FDate END,
					@tempToDate		= @TDate

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
				Creator,
				Description,
				CalculatedType
			)
			SELECT
				0,
				MonthDate,
				TransType,
				SUM(Amount),
				'B/F' AS Status,
				'System' AS Creator,
				CASE WHEN MonthDate >= CONVERT(DATE, GETDATE()) THEN 'Current ' ELSE 'UnCalculated ' END
					+ CASE WHEN TransType = 201 THEN 'Monthly Earning' ELSE 'Revenue Share' END AS Description,
				CASE WHEN MonthDate >= CONVERT(DATE, GETDATE()) THEN 0 ELSE 1 END AS CalculatedType
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

	-- Return data
	SELECT @NRows = COUNT(1) FROM #tempData WHERE TransType <> 204

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		TransId,
		MonthDate,
		TransType,
		Amount,
		Status,
		Creator,
		Description,
		CalculatedType
	FROM
	(
		SELECT
			TransId,
			MonthDate,
			TransType,
			Amount,
			Status,
			Creator,
			Description,
			CalculatedType,
			DENSE_RANK() OVER(ORDER BY MonthDate DESC, CASE WHEN TransType IN (201, 204) THEN 0 ELSE TransId END DESC) AS RowNum
		FROM #tempData
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempData
END
GO