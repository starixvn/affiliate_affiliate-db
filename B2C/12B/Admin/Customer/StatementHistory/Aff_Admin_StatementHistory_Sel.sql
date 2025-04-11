/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_StatementHistory_Sel] 
	@AffId		INT,
	@FDate		SMALLDATETIME = NULL,
	@TDate		SMALLDATETIME = NULL,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Statement History

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241225@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250404@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MinReportDate SMALLDATETIME
		,@EndOfTDate DATETIME
		,@CurrentDate SMALLDATETIME 

	DECLARE @AffGroupInfo TABLE (MonthDate SMALLDATETIME, GroupTypeName NVARCHAR(100))

	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)	
	SELECT  @CurrentDate   = CONVERT(DATE, DATEADD(HOUR, 12, GETDATE()))

	IF @FDate IS NULL OR @TDate IS NULL
		SELECT @FDate = @MinReportDate, @TDate = @CurrentDate
	ELSE
	BEGIN
		SELECT @FDate = CONVERT(DATE, @FDate), @TDate = CONVERT(DATE, @TDate)
		
		IF @FDate < @MinReportDate
			SELECT @FDate = @MinReportDate
	END

	IF @FDate > @TDate
		RETURN

	SELECT @EndOfTDate = EOMONTH(@TDate) -- Last day of @TDate
	
	-- Get GroupType Info
	INSERT INTO @AffGroupInfo (MonthDate, GroupTypeName)
	SELECT af.MonthDate
		,af.GroupTypeName
	FROM dbo.Aff_f_AffGroupInfo_Sel(@FDate, @EndOfTDate, CONVERT(VARCHAR(20), @AffId)) af

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
			DATEADD(HOUR, 12, at.TransDate) AS TransDate, -- Changed from GMT-4 to GMT+12
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
			AND at.WinlostDate >= @FDate AND at.WinlostDate < DATEADD(DAY, 1, @TDate)
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
				SELECT md.MonthDate, at.TransType, ISNULL(at.Amount, 0) AS Amount
				FROM CTE_MonthDate md
					OUTER APPLY (
						SELECT at.TransType, at.Amount
						FROM dbo.AffTrans at WITH (NOLOCK)
						WHERE md.MonthDate = at.WinlostDate
							AND at.AffId = @AffId
							AND at.TransType IN (201, 204)
					) at
			) t
			GROUP BY MonthDate, TransType
			OPTION (MAXRECURSION 0)
		END

		-- Uncalculated months
		DECLARE @AffIds VARCHAR(20)
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
				NetTurnover			MONEY,
				ActivePlayer		INT,
				QualifiedMember		INT DEFAULT (0),
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
				QualifiedMember,
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
				CASE WHEN MonthDate >= @CurrentDate THEN 'Current ' ELSE 'UnCalculated ' END
					+ CASE WHEN TransType = 201 THEN 'Monthly Earning' ELSE 'Revenue Share' END AS Description,
				CASE WHEN MonthDate >= @CurrentDate THEN 0 ELSE 1 END AS CalculatedType
			FROM (
				SELECT md.MonthDate,TransType, ISNULL(at.Amount, 0) AS Amount
				FROM CTE_MonthDate md
					OUTER APPLY (
						SELECT c.Commission, c.SubAffCommission
						FROM #TempCommission c
						WHERE md.MonthDate = c.MonthDate
							AND c.AffId = @AffId
							AND c.ProductId = 0
					) c
					OUTER APPLY (
						SELECT 201 AS TransType, c.Commission AS Amount
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
		result.MonthDate,
		TransType,
		Amount,
		Status,
		Creator,
		CASE WHEN result.TransType = 201 AND ISNULL(ag.GroupTypeName, '') <> '' THEN CONCAT(RESULT.Description,' (',ag.GroupTypeName,')')ELSE  Description END AS Description,
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
		LEFT JOIN @AffGroupInfo ag ON ag.MonthDate = result.MonthDate
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempData
END
GO