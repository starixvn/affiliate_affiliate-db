/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_StatementHistory_Sel] 
	@AffId		INT,
	@TransType	INT = - 1,
	@FDate		SMALLDATETIME = NULL,
	@TDate		SMALLDATETIME = NULL,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@TotalPages INT = 0 OUTPUT,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Customer - Statement History

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181012@Percy: Missing data today [RedmineID: #103143]
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
		TransId		BIGINT,
		MonthDate	SMALLDATETIME,
		TransType	INT,
		Amount		MONEY,
		Status		VARCHAR(10),
		Creator		NVARCHAR(50),
		Description	NVARCHAR(2000)
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
		IF @FDate < @MaxCommDate
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
				ISNULL(at.TransId, 0),
				md.MonthDate,
				201 AS TransType,
				ISNULL(at.Amount, 0),
				'B/F' AS Status,
				'System' AS Creator,
				'Monthly Earning' AS Description
			FROM CTE_MonthDate md
				LEFT JOIN dbo.AffTrans at WITH (NOLOCK) ON md.MonthDate = at.TransDate AND at.AffId = @AffId AND at.TransType = 201
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
				MonthDate		SMALLDATETIME,
				AffId			INT,
				GroupId			INT,
				ProductId		INT,
				Deposit			MONEY,
				Withdrawal		MONEY,
				Bonus			MONEY,
				Turnover		MONEY,
				Winloss			MONEY,
				-- Fees
				PlatFormFee		MONEY,
				OperationalFee	MONEY,
				BankingFee		MONEY,
				-- Calculation
				NetWinloss		MONEY,
				ActivePlayer	INT,
				QualifiedMember INT,
				QMTurnover		MONEY,
				CommissionRate	FLOAT,
				Commission		MONEY
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
				TransId,
				MonthDate,
				TransType,
				Amount,
				Status,
				Creator,
				Description
			)
			SELECT
				0 AS TransId,
				MonthDate,
				0 AS TransType,
				Commission AS Amount,
				'Current' AS Status,
				'' AS Creator,
				CASE WHEN MonthDate >= CONVERT(DATE, GETDATE()) THEN 'Current Month Statistics' ELSE 'UnCalculated Month' END AS Description
			FROM #TempCommission

			DROP TABLE #TempCommission
		END
	END

	-- Return data
	SELECT @NRows = COUNT(1) FROM #tempData

	SELECT @TotalPages = @NRows/@PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END

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
		Description
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
			ROW_NUMBER() OVER(ORDER BY MonthDate DESC) AS Rownum
		FROM #tempData
	) AS result
	WHERE Rownum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempData
END
GO