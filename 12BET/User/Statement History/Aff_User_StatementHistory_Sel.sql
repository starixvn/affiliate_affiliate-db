/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_StatementHistory_Sel]
	@AffId		INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 50,
	@TotalPages INT = 0 OUTPUT,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task:
		User site - Statement History
		Admin site - Customer - Statement History

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempData
	(
		MonthDate	SMALLDATETIME,
		TransType	INT,
		Amount		MONEY,
		Status		VARCHAR(10),
		Description	NVARCHAR(2000)
	)

	-- Payment, Adjustment info (TransType = 202, 203)
	BEGIN
		INSERT INTO #tempData
		(
			MonthDate,
			TransType,
			Amount,
			Status,
			Description
		)
		SELECT
			at.TransDate,
			at.TransType,
			CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount,
			CASE WHEN at.TransType = 202 THEN at.Status ELSE 'B/F' END AS Status,
			CASE at.TransType WHEN 202 THEN ap.AffDesc WHEN 203 THEN '' ELSE at.Description END AS Description
		FROM dbo.AffTrans at WITH (NOLOCK)
			LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID AND at.TransType = 202
		WHERE at.AffId = @AffId
			AND at.TransType IN (202, 203)
	END

	-- Commission info
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		-- Calculated months
		SELECT	@tempFromDate = dbo.Aff_f_GetMinReportDate(@AffId), @tempToDate = @MaxCommDate

		IF @tempFromDate <= @tempToDate
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFromDate) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempToDate
			)
			INSERT INTO #tempData
			(
				MonthDate,
				TransType,
				Amount,
				Status,
				Description
			)
			SELECT
				md.MonthDate,
				201 AS TransType,
				ISNULL(at.Amount, 0),
				'B/F' AS Status,
				'Monthly Earning' AS Description
			FROM CTE_MonthDate md
				LEFT JOIN dbo.AffTrans at WITH (NOLOCK) ON md.MonthDate = at.TransDate AND at.AffId = @AffId AND at.TransType = 201
			OPTION (MAXRECURSION 0)
		END

		-- Uncalculated months
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)
		
		SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
				@tempToDate		= CONVERT(DATE, GETDATE())

		CREATE TABLE #TempCommission
		(
			MonthDate				SMALLDATETIME,
			AffId					INT,
			GroupId					INT,
			ProductId				INT,
			Deposit					MONEY,
			Withdrawal				MONEY,
			Bonus					MONEY,
			Turnover				MONEY,
			Winloss					MONEY,
			AWinloss				MONEY,
			AComm					MONEY,
			-- Fees
			PlatFormFee				MONEY,
			OperationalFee			MONEY,
			BankingFee				MONEY,
			ExchangeWinlossShare	MONEY,
			ExchangeCommShare		MONEY,
			-- Calculation
			GrossWinloss			MONEY,
			NetWinloss				MONEY,
			ActivePlayer			INT,
			QualifiedMember			INT,
			QMTurnover				MONEY,
			CommissionRate			FLOAT,
			Commission				MONEY
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
			Turnover,
			Winloss,
			AWinloss,
			AComm,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			ExchangeWinlossShare,
			ExchangeCommShare,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission
		)
		EXEC dbo.Aff_Commission_UnCalc
			@AffIds				= @AffIds,
			@FromMonthDate		= @tempFromDate,
			@ToMonthDate		= @tempToDate,
			@ProductIds			= '0',
			@IsSumAll			= 0,
			@GetRowTotalOnly	= 1
		
		INSERT INTO #tempData
		(
			MonthDate,
			TransType,
			Amount,
			Status,
			Description
		)
		SELECT
			MonthDate,
			0 AS TransType,
			Commission AS Amount,
			'Current' AS Status,
			CASE WHEN MonthDate >= CONVERT(DATE, GETDATE()) THEN 'Current Month Statistics' ELSE 'UnCalculated Month' END AS Description
		FROM #TempCommission

		DROP TABLE #TempCommission
	END

	-- Return data
	SELECT @NRows = COUNT(1) FROM #tempData

	SELECT @TotalPages = @NRows/@PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		MonthDate,
		TransType,
		Amount,
		Status,
		Description
	FROM
	(
		SELECT
			MonthDate,
			TransType,
			Amount,
			Status,
			Description,
			ROW_NUMBER() OVER(ORDER BY MonthDate DESC) AS Rownum
		FROM #tempData
	) AS result
	WHERE Rownum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempData
END
GO