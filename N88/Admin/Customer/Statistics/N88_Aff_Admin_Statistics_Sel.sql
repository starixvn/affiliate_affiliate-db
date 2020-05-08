/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Statistics_Sel] 
	@AffId		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin site - Customer - Statistics

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SignupsByMonth				INT,
			@SignupsTotal				INT,
			@FDMByMonth					INT,
			@FDMTotal					INT,
			@ActivePlayersByMonth		INT,
			@QualifiedMembersByMonth	INT,
			@DepositByMonth				MONEY,
			@DepositTotal				MONEY,
			@TurnoverByMonth			MONEY,
			@TurnoverTotal				MONEY,
			@WinlostByMonth				MONEY,
			@WinlostTotal				MONEY,
			@UniqueClickPCByMonth		INT,
			@TotalClickPCByMonth		INT,
			@UniqueClickMobileByMonth	INT,
			@TotalClickMobileByMonth	INT,
			@NoOfSubAffByMonth			INT,
			@NoOfSubAffTotal			INT

	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT	@FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT	@ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	-- member statistics
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @IsSumAll BIT, @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(MAX), @AffId)

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

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

		-- Uncalculated Months
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= CONVERT(DATE, GETDATE())

			SELECT  @IsSumAll = CASE WHEN @MonthDate >= @tempFromDate THEN 0 ELSE 1 END

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
				@IsSumAll			= @IsSumAll,
				@GetRowTotalOnly	= 1
		END

		-- Calculated Months
		BEGIN
			SELECT	@tempFromDate	= dbo.Aff_f_GetMinReportDate(@AffId),
					@tempToDate		= @MaxCommDate

			SELECT  @IsSumAll = CASE WHEN @MonthDate <= @tempToDate THEN 0 ELSE 1 END

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
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@IsSumAll			= @IsSumAll,
				@GetRowTotalOnly	= 1
		END
	END

	SELECT
		@QualifiedMembersByMonth	= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(QualifiedMember, 0) ELSE 0 END),
		@ActivePlayersByMonth		= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(ActivePlayer, 0) ELSE 0 END),
		@DepositByMonth				= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Deposit, 0) ELSE 0 END),
		@TurnoverByMonth			= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Turnover, 0) ELSE 0 END),
		@WinlostByMonth				= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Winloss, 0) ELSE 0 END),
		@DepositTotal				= SUM(ISNULL(Deposit, 0)),
		@TurnoverTotal				= SUM(ISNULL(Turnover, 0)),
		@WinlostTotal				= SUM(ISNULL(Winloss, 0))
	FROM #TempCommission

	DROP TABLE #TempCommission

	SELECT
		@SignupsTotal	= COUNT(1),
		@FDMTotal		= COUNT(CreatedDate),
		@SignupsByMonth = COUNT(CASE WHEN RegisteredDate >= @FromBeginMonth AND RegisteredDate < @ToNextMonth THEN 1 ELSE NULL END),
		@FDMByMonth		= COUNT(CASE WHEN CreatedDate >= @FromBeginMonth AND CreatedDate < @ToNextMonth THEN 1 ELSE NULL END)
	FROM dbo.MemberInfo WITH (NOLOCK)
	WHERE AffId = @AffId

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
	SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromBeginMonth))

	;WITH CTE_Device AS (
		SELECT DeviceType, SUM(TotalClick) AS TotalClickByMonth, SUM(UniqueClick) AS UniqueClicks
		FROM (
			SELECT
				ISNULL(c.DeviceType, 0) AS DeviceType,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT c.IP) AS UniqueClick
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE c.AffId = @AffId
				AND c.Date >= @FromBeginMonth AND c.Date < @ToNextMonth
				AND c.Date > @ArchiveDate
			GROUP BY ISNULL(c.DeviceType, 0), c.Date

			UNION ALL
			SELECT
				ISNULL(c.DeviceType, 0) AS DeviceType,
				SUM(TotalClick) AS TotalClick,
				SUM(UniqueClick) AS UniqueClick
			FROM dbo.ClickStatisticsSum c WITH (NOLOCK)
			WHERE c.AffId = @AffId
				AND c.Date >= @FromBeginMonth AND c.Date < @ToNextMonth
				AND c.Date <= @ArchiveDate
			GROUP BY ISNULL(c.DeviceType, 0), c.Date
		) AS A
		GROUP BY DeviceType
	)
	SELECT
		@TotalClickPCByMonth		= SUM(CASE WHEN DeviceType = 0 THEN ISNULL(TotalClickByMonth, 0) ELSE 0 END),
		@UniqueClickPCByMonth		= SUM(CASE WHEN DeviceType = 0 THEN ISNULL(UniqueClicks, 0) ELSE 0 END),
		@TotalClickMobileByMonth	= SUM(CASE WHEN DeviceType = 1 THEN ISNULL(TotalClickByMonth, 0) ELSE 0 END),
		@UniqueClickMobileByMonth	= SUM(CASE WHEN DeviceType = 1 THEN ISNULL(UniqueClicks, 0) ELSE 0 END)
	FROM CTE_Device

	SELECT
		@NoOfSubAffTotal	= COUNT(1),
		@NoOfSubAffByMonth	= COUNT(CASE WHEN ApprovedDate >= @FromBeginMonth AND ApprovedDate < @ToNextMonth THEN 1 ELSE NULL END)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE ParentAffId = @AffId
		AND Status = 'Approved'
		AND IsClosed = 0

	-- Return data
	SELECT
		ISNULL(@SignupsByMonth, 0)				AS SignupsByMonth,
		ISNULL(@SignupsTotal, 0)				AS SignupsTotal,
		ISNULL(@FDMByMonth, 0)					AS FDMByMonth,
		ISNULL(@FDMTotal, 0)					AS FDMTotal,
		ISNULL(@ActivePlayersByMonth, 0)		AS ActivePlayersByMonth,
		ISNULL(@QualifiedMembersByMonth, 0)		AS QualifiedMembersByMonth,
		ISNULL(@DepositByMonth, 0)				AS DepositByMonth,
		ISNULL(@DepositTotal, 0)				AS DepositTotal,
		ISNULL(@TurnoverByMonth, 0)				AS TurnoverByMonth,
		ISNULL(@TurnoverTotal, 0)				AS TurnoverTotal,
		ISNULL(@WinlostByMonth, 0)				AS WinlostByMonth,
		ISNULL(@WinlostTotal, 0)				AS WinlostTotal,
		ISNULL(@UniqueClickPCByMonth, 0)		AS UniqueClickPCByMonth,
		ISNULL(@TotalClickPCByMonth, 0)			AS TotalClickPCByMonth,
		ISNULL(@TotalClickMobileByMonth, 0)		AS TotalClickMobileByMonth,
		ISNULL(@UniqueClickMobileByMonth, 0)	AS UniqueClickMobileByMonth,
		ISNULL(@NoOfSubAffByMonth, 0)			AS NoOfSubAffByMonth,
		ISNULL(@NoOfSubAffTotal, 0)				AS NoOfSubAffTotal
END
GO