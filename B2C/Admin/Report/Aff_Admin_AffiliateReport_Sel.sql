/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@Username			NVARCHAR(50) = NULL
	,@GroupId 			INT = 0
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@PreferredLanguage	VARCHAR(11) = NULL
	,@ProductIds		VARCHAR(MAX) = '0'
	,@Currencies		VARCHAR(MAX) = ''
	,@BaseCurrency		INT = 0
	,@SortType			TINYINT = 1
	,@SortDirectionType	BIT = 0
	,@IsExportExcel		BIT = 0
	,@PageIndex			INT = 1
	,@PageSize			INT = 50
	,@NRows				INT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Report - Affiliate Report

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
		- 20210223@Percy: Add Commission Group filter [RedmineID: #150493]
		- 20210323@Percy: Missing FDM [RedmineID: #151391]

	Param's Explanation:
		- @SortType: 1: Affiliate username, 2: Turnover, 3: Winloss, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
*/

BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NULL OR @ToDate IS NULL
		RETURN

	SELECT  @Username = ISNULL(LTRIM(RTRIM(@Username)), ''), @PreferredLanguage = ISNULL(@PreferredLanguage, ''), @GroupId = ISNULL(@GroupId, 0)

	SELECT  @FromDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0) -- Begin Of Month
	SELECT  @ToDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Of Month

	DECLARE  @EndOfCurrentMonth SMALLDATETIME, @NoOfMonth INT
	SELECT   @EndOfCurrentMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	IF @ToDate > @EndOfCurrentMonth
		SELECT @ToDate = @EndOfCurrentMonth

	SELECT @NoOfMonth = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NoOfMonth <= 0
		RETURN

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	;WITH CTE_MonthDate AS
	(
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)) AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @ToDate
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT MonthDate FROM CTE_MonthDate
	OPTION (MAXRECURSION 0)

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

	/*
		===== Get data =====
	*/
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
			-- Fees
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
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

		IF @FromDate <= @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= @FromDate
			SELECT @tempToDate		= CASE WHEN @ToDate > @MaxCommDate THEN @MaxCommDate ELSE @ToDate END

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
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
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
				@AffIds				= 'all',
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END
			SELECT @tempToDate		= @ToDate
			
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
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
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
				@AffIds				= 'all',
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@Currencies			= @Currencies,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		-- Statistics
		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME
		SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatistics_bk WITH (NOLOCK)

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tempToDate	= @ToDate

			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM 
			(
				SELECT
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT IP) AS UniqueClick
				FROM dbo.ClickStatistics WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0))
			) AS c
			GROUP BY AffId
		END

		IF @FromDate <= @ArchiveDate
		BEGIN
			SELECT @tempFromDate = @FromDate
			SELECT @tempToDate	= CASE WHEN @ToDate > @ArchiveDate THEN @ArchiveDate ELSE @ToDate END
			
			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), COUNT(1) AS UniqueClick
			FROM
			(
				SELECT
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					IP,
					COUNT(1) AS TotalClick
				FROM dbo.ClickStatistics_bk WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)),
					IP
			) AS c
			GROUP BY AffId
		END

		-- Signup, FDM
		CREATE TABLE #Signup (AffId INT, Signup INT, FDM INT)
		INSERT INTO #Signup (AffId, Signup, FDM)
		SELECT mi.AffId
			,COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE NULL END) AS Signup
			,COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
		WHERE NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mi.CustId = mr.CustId
						AND mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
				)
		GROUP BY mi.AffId

		-- AffWithdrawal, AffAdjustment
		CREATE TABLE #AffTrans (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY)
		INSERT INTO #AffTrans (AffId, AffWithdrawal, AffAdjustment, BFF)
		SELECT AffId,
			SUM(CASE WHEN TransType = 202 AND TransDate >= @FromDate THEN ABS(Amount) ELSE 0 END) AS AffWithdrawal,
			SUM(CASE WHEN TransType = 203 AND TransDate >= @FromDate THEN Amount ELSE 0 END) AS AffAdjustment,
			SUM(Amount) AS BFF
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE TransDate < DATEADD(DAY, 1, @ToDate)
			AND Status IN ('Pending', 'Approved', 'Completed')
		GROUP BY AffId
	END
	
	-- Return data
	BEGIN
		CREATE TABLE #Result
		(
			AffId			INT,
			Username		NVARCHAR(30),
			TotalClick		INT,
			UniqueClick		INT,
			Signup			INT,
			FDM				INT,
			ActiveMember	INT,
			QualifiedMember INT,
			NoOfSubAff		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Turnover		MONEY,
			Winlost			MONEY,
			Bonus			MONEY,
			Rebate			MONEY,
			PlatFormFee		MONEY,
			OperationalFee	MONEY,
			DepositFee		MONEY,
			WithdrawalFee	MONEY,
			CommissionRate	MONEY,
			Earning			MONEY,
			SubAffEarning	MONEY,
			AffWithdrawal	MONEY,
			AffAdjustment	MONEY,
			BFF				MONEY,
			RowIdx			INT
		)
		INSERT INTO #Result
		(
			AffId,
			Username,
			TotalClick,
			UniqueClick,
			Signup,
			FDM,
			ActiveMember,
			QualifiedMember,
			NoOfSubAff,
			Deposit,
			Withdrawal,
			Turnover,
			Winlost,
			Bonus,
			Rebate,
			PlatFormFee,
			OperationalFee,
			DepositFee,
			WithdrawalFee,
			CommissionRate,
			Earning,
			SubAffEarning,
			AffWithdrawal,
			AffAdjustment,
			BFF,
			RowIdx
		)
		SELECT
			ai.AffId,
			ai.Username,
			ISNULL(s.TotalClick, 0)			AS TotalClick,
			ISNULL(s.UniqueClick, 0)		AS UniqueClick,
			ISNULL(su.Signup, 0)			AS Signup,
			ISNULL(su.FDM, 0)				AS FDM,
			ISNULL(tc.ActivePlayer, 0)		AS ActiveMember,
			ISNULL(tc.QualifiedMember, 0)	AS QualifiedMember,
			ISNULL(a.NoOfSubAff, 0)			AS NoOfSubAff,
			ISNULL(tc.Deposit, 0)			AS Deposit,
			ISNULL(tc.Withdrawal, 0)		AS Withdrawal,
			ISNULL(tc.Turnover, 0)			AS Turnover,
			ISNULL(tc.Winloss, 0)			AS Winlost,
			ISNULL(tc.Bonus, 0)				AS Bonus,
			ISNULL(tc.Rebate, 0)			AS Rebate,
			ISNULL(tc.PlatFormFee, 0)		AS PlatFormFee,
			ISNULL(tc.OperationalFee, 0)	AS OperationalFee,
			ISNULL(tc.DepositFee, 0)		AS DepositFee,
			ISNULL(tc.WithdrawalFee, 0)		AS WithdrawalFee,
			ISNULL(tc.CommissionRate, 0)	AS CommissionRate,
			ISNULL(tc.Commission, 0)		AS Earning,
			ISNULL(tc.SubAffCommission, 0)	AS SubAffEarning,
			ISNULL(at.AffWithdrawal, 0)		AS AffWithdrawal,
			ISNULL(at.AffAdjustment, 0)		AS AffAdjustment,
			ISNULL(at.BFF, 0)				AS BFF,
			ROW_NUMBER() OVER(ORDER BY
				CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN ai.Username END ASC,
				CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN ai.Username END DESC,
				CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(tc.Turnover, 0) END ASC,
				CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(tc.Turnover, 0) END DESC,
				CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(tc.Winloss, 0) END ASC,
				CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(tc.Winloss, 0) END DESC,
				CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(tc.Commission, 0) END ASC,
				CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(tc.Commission, 0) END DESC) AS RowIdx
		FROM dbo.AffInfo ai WITH (NOLOCK)
			LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			LEFT JOIN #Signup su ON ai.AffId = su.AffId
			LEFT JOIN #AffTrans at ON ai.AffId = at.AffId
			LEFT JOIN (
				SELECT AffId, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
				FROM #Statistics
				GROUP BY AffId
			) s ON ai.AffId = s.AffId
			LEFT JOIN (
				SELECT AffId,
					SUM(ActivePlayer)				AS ActivePlayer,
					SUM(QualifiedMember)			AS QualifiedMember,
					SUM(Deposit)					AS Deposit,
					SUM(Withdrawal)					AS Withdrawal,
					SUM(Turnover)					AS Turnover,
					SUM(Winloss)					AS Winloss,
					SUM(Bonus)						AS Bonus,
					SUM(Rebate)						AS Rebate,
					SUM(PlatFormFee)				AS PlatFormFee,
					SUM(OperationalFee)				AS OperationalFee,
					SUM(DepositFee)					AS DepositFee,
					SUM(WithdrawalFee)				AS WithdrawalFee,
					SUM(NetWinloss)					AS NetWinloss,
					SUM(CommissionRate/@NoOfMonth)	AS CommissionRate,
					SUM(Commission)					AS Commission,
					SUM(SubAffCommission)			AS SubAffCommission
				FROM #TempCommission
				GROUP BY AffId
			) tc ON ai.AffId = tc.AffId
			LEFT JOIN (
				SELECT ParentAffId, COUNT(1) AS NoOfSubAff
				FROM dbo.AffInfo WITH (NOLOCK)
				WHERE Status = 'Approved'
					AND ApprovedDate >= @FromDate AND ApprovedDate < DATEADD(DAY, 1, @ToDate)
				GROUP BY ParentAffId
			) a ON ai.AffId = a.ParentAffId
		WHERE ai.Status = 'Approved'
			AND ai.Username LIKE '%' + @Username + '%'
			AND (@PreferredLanguage = '' OR ad.PreferredLanguage = @PreferredLanguage)
			AND (
				@GroupId = 0
				OR EXISTS (SELECT 1 FROM dbo.AffGroupHistory agh WITH (NOLOCK) WHERE agh.AffId = ai.AffId AND agh.GroupId = @GroupId AND agh.MonthDate BETWEEN @FromDate AND @ToDate)
			)
			AND ai.ApprovedDate < DATEADD(DAY, 1, @ToDate)
	END

	SELECT @NRows = COUNT(1) FROM #Result
	IF @NRows = 0
		RETURN
		
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
		SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1
	ELSE
		SELECT @RowStart = 1, @RowEnd = @NRows

	-- Return detail
	SELECT AffId, Username, TotalClick, UniqueClick, Signup, FDM, ActiveMember, QualifiedMember, NoOfSubAff
		,Deposit, Withdrawal, Turnover, Winlost, Bonus, Rebate, PlatFormFee, OperationalFee, DepositFee, WithdrawalFee
		,PlatFormFee + OperationalFee + DepositFee + WithdrawalFee AS TotalFee
		,CommissionRate, Earning, SubAffEarning, AffWithdrawal, AffAdjustment, BFF
	FROM #Result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY RowIdx

	-- Return total
	SELECT
		SUM(TotalClick)			AS TotalClick
		,SUM(UniqueClick)		AS UniqueClick
		,SUM(Signup)			AS Signup
		,SUM(FDM)				AS FDM
		,SUM(ActiveMember)		AS ActiveMember
		,SUM(QualifiedMember)	AS QualifiedMember
		,SUM(NoOfSubAff)		AS NoOfSubAff
		,SUM(Deposit)			AS Deposit
		,SUM(Withdrawal)		AS Withdrawal
		,SUM(Turnover)			AS Turnover
		,SUM(Winlost)			AS Winlost
		,SUM(Bonus)				AS Bonus
		,SUM(Rebate)			AS Rebate
		,SUM(PlatFormFee)		AS PlatFormFee
		,SUM(OperationalFee)	AS OperationalFee
		,SUM(DepositFee)		AS DepositFee
		,SUM(WithdrawalFee)		AS WithdrawalFee
		,SUM(PlatFormFee + OperationalFee + DepositFee + WithdrawalFee) AS TotalFee
		,0 AS CommissionRate
		,SUM(Earning)			AS Earning
		,SUM(SubAffEarning)		AS SubAffEarning
		,SUM(AffWithdrawal)		AS AffWithdrawal
		,SUM(AffAdjustment)		AS AffAdjustment
		,SUM(BFF)				AS BFF
	FROM #Result

	DROP TABLE #AffTrans
	DROP TABLE #Result
	DROP TABLE #Signup
	DROP TABLE #Statistics
	DROP TABLE #TempCommission
END
GO