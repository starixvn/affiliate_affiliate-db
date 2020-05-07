/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_StatementHistory_Sel]
	@AffId		INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 50,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Statement History

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempData
	(
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
				t.TransType,
				ISNULL(at.Amount, 0),
				'B/F' AS Status,
				t.Description
			FROM CTE_MonthDate md
				CROSS APPLY (
					SELECT 201 AS TransType, 'Monthly Earning' AS Description
					UNION ALL
					SELECT 204 AS TransType, 'Commission Bonus' AS Description
				) t
				OUTER APPLY (
					SELECT at.TransId, at.Amount
					FROM dbo.AffTrans at WITH (NOLOCK)
					WHERE md.MonthDate = at.TransDate
						AND at.AffId = @AffId
						AND at.TransType = t.TransType
				) at
			OPTION (MAXRECURSION 0)
		END

		-- Uncalculated months
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)
		
		SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
				@tempToDate		= CONVERT(DATE, GETDATE())

		CREATE TABLE #TempCommission
		(
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
			Deposit				MONEY,
			Withdrawal			MONEY,
			Bonus				MONEY,
			Turnover			MONEY,
			Winloss				MONEY,
			-- Fees
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			BankingFee			MONEY,
			-- Calculation
			GrossWinloss		MONEY,
			NetWinloss			MONEY,
			ActivePlayer		INT,
			QualifiedMember		INT,
			QMTurnover			MONEY,
			CommissionRate		FLOAT,
			Commission			MONEY,
			SubAffCommission	MONEY
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
			PlatFormFee,
			OperationalFee,
			BankingFee,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission,
			SubAffCommission
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
			MonthDate,
			TransType,
			Amount,
			Status,
			Description,
			CalculatedType
		)
		SELECT
			md.MonthDate,
			t.TransType,
			ISNULL(at.Amount, 0) AS Amount,
			'Current' AS Status,
			CASE WHEN md.MonthDate >= CONVERT(DATE, GETDATE()) THEN 'Current ' ELSE 'UnCalculated ' END + t.Description AS Description,
			CASE WHEN md.MonthDate >= CONVERT(DATE, GETDATE()) THEN 0 ELSE 1 END AS CalculatedType
		FROM CTE_MonthDate md
			CROSS APPLY (
				SELECT 201 AS TransType, 'Monthly Earning' AS Description
				UNION ALL
				SELECT 204 AS TransType, 'Commission Bonus' AS Description
			) t
			OUTER APPLY (
				SELECT CASE WHEN t.TransType = 201 THEN c.Commission ELSE c.SubAffCommission END AS Amount
				FROM #TempCommission c
				WHERE md.MonthDate = c.MonthDate
			) at
		OPTION (MAXRECURSION 0)

		DROP TABLE #TempCommission
	END

	-- Return data
	SELECT @NRows = COUNT(1) FROM #tempData WHERE TransType <> 204

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		MonthDate,
		TransType,
		Amount,
		Status,
		Description,
		CalculatedType
	FROM
	(
		SELECT
			MonthDate,
			TransType,
			Amount,
			Status,
			Description,
			CalculatedType,
			DENSE_RANK() OVER(ORDER BY MonthDate DESC, CASE WHEN TransType IN (201, 204) THEN 0 ELSE TransType END DESC) AS RowNum
		FROM #tempData
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempData
END
GO