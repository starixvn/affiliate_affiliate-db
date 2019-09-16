/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@Username			NVARCHAR(50) = NULL,
	@FromDate			SMALLDATETIME,
	@ToDate				SMALLDATETIME,
	@PreferredLanguage	VARCHAR(11) = NULL,
	@ProductIds			VARCHAR(MAX) = '0',
	@SortType			TINYINT = 1,
	@SortDirectionType	BIT = 0,
	@IsExportExcel		BIT = 0,
	@PageIndex			INT = 1,
	@PageSize			INT = 50,
	@NRows				INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin site - Report - Affiliate Report

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Support export excel [RedmineID: #102322]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]

	Param's Explanation:
		- @SortType: 1: Affiliate username, 2: Turnover, 3: Winloss, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
*/

BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NULL OR @ToDate IS NULL
		RETURN

	SELECT  @Username = ISNULL(LTRIM(RTRIM(@Username)), ''), @PreferredLanguage = ISNULL(@PreferredLanguage, '')

	DECLARE @IsFiltered BIT
	SELECT  @IsFiltered = CASE WHEN @Username <> '' OR @PreferredLanguage <> '' THEN 1 ELSE 0 END

	SELECT  @FromDate		= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0) -- Begin Of Month
	SELECT  @ToDate			= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Of Month

	DECLARE @MinReportDate SMALLDATETIME, @EndOfCurrentMonth SMALLDATETIME, @NoOfMonth INT
	SELECT  @MinReportDate		= dbo.Aff_f_GetMinReportDate(0)
	SELECT  @EndOfCurrentMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	IF @FromDate < @MinReportDate
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MinReportDate), 0)

	IF @ToDate > @EndOfCurrentMonth
		SELECT @ToDate = @EndOfCurrentMonth

	SELECT @NoOfMonth = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NoOfMonth <= 0
		RETURN

	/*
		===== Total page =====
	*/
	CREATE TABLE #AffInfo (AffId INT PRIMARY KEY, Username NVARCHAR(50))
	INSERT INTO #AffInfo (AffId, Username)
	SELECT ai.AffId, ai.Username
	FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.Status = 'Approved'
		AND ai.Username LIKE '%' + @Username + '%'
		AND (@PreferredLanguage = '' OR ad.PreferredLanguage = @PreferredLanguage)

	SELECT @NRows = @@ROWCOUNT

	IF @NRows = 0
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
		-- Affiliates have place bet data
		CREATE TABLE #AffData
		(
			AffId			INT,
			ActivePlayer	INT,
			QualifiedMember	INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			Bonus			MONEY,
			PlatFormFee		MONEY,
			OperationalFee	MONEY,
			BankingFee		MONEY,
			NetWinloss		MONEY,
			CommissionRate	FLOAT,
			Commission		MONEY
		)

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
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= 'all',
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
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
				@AffIds				= 'all',
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		INSERT INTO #AffData
		(
			AffId,
			ActivePlayer,
			QualifiedMember,
			Deposit,
			Withdrawal,
			Turnover,
			Winloss,
			Bonus,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			NetWinloss,
			CommissionRate,
			Commission
		)
		SELECT
			AffId,
			SUM(ActivePlayer)				AS ActivePlayer,
			SUM(QualifiedMember)			AS QualifiedMember,
			SUM(Deposit)					AS Deposit,
			SUM(Withdrawal)					AS Withdrawal,
			SUM(Turnover)					AS Turnover,
			SUM(Winloss)					AS Winloss,
			SUM(Bonus)						AS Bonus,
			SUM(PlatFormFee)				AS PlatFormFee,
			SUM(OperationalFee)				AS OperationalFee,
			SUM(BankingFee)					AS BankingFee,
			SUM(NetWinloss)					AS NetWinloss,
			SUM(CommissionRate/@NoOfMonth)	AS CommissionRate,
			SUM(Commission)					AS Commission
		FROM #TempCommission
		GROUP BY
			AffId

		DROP TABLE #TempCommission

		-- Signup
		CREATE TABLE #Signup (AffId INT, Signup INT)

		DECLARE @sql NVARCHAR(MAX)
		SELECT  @sql = 'SELECT a.AffId, a.Signup
						FROM OPENQUERY(DBDEPOSIT, ''SELECT AffiliateId AS AffId, COUNT(1) AS Signup FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
													WHERE creatdate >= ''''' + CONVERT(VARCHAR(10), @FromDate, 120) + ''''' AND
														creatdate < ''''' + + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120) + '''''
													GROUP BY AffiliateId'') AS a'
		INSERT INTO #Signup (AffId, Signup)
		EXEC (@sql)
	END
	
	/*
		===== Paging ====
	*/
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT

		IF @IsExportExcel = 0
		BEGIN
			SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
					@RowEnd = @RowStart + @PageSize - 1
		END
		ELSE
		BEGIN
			SELECT  @RowStart = 1,
					@RowEnd = @NRows
		END

		CREATE TABLE #AffPaging
		(
			RowIdx			INT,
			AffId			INT,
			Username		NVARCHAR(50),
			ActivePlayer	INT,
			QualifiedMember	INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			Bonus			MONEY,
			PlatFormFee		MONEY,
			OperationalFee	MONEY,
			BankingFee		MONEY,
			NetWinloss		MONEY,
			CommissionRate	FLOAT,
			Commission		MONEY
		)

		INSERT INTO #AffPaging
		(
			RowIdx,
			AffId,
			Username,
			ActivePlayer,
			QualifiedMember,
			Deposit,
			Withdrawal,
			Turnover,
			Winloss,
			Bonus,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			NetWinloss,
			CommissionRate,
			Commission
		)
		SELECT
			RowIdx,
			AffId,
			Username,
			ActivePlayer,
			QualifiedMember,
			Deposit,
			Withdrawal,
			Turnover,
			Winloss,
			Bonus,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			NetWinloss,
			CommissionRate,
			Commission
		FROM
		(
			SELECT
				ai.AffId,
				ai.Username,
				ISNULL(d.ActivePlayer, 0)		AS ActivePlayer,
				ISNULL(d.QualifiedMember, 0)	AS QualifiedMember,
				ISNULL(d.Deposit, 0)			AS Deposit,
				ISNULL(d.Withdrawal, 0)			AS Withdrawal,
				ISNULL(d.Turnover, 0)			AS Turnover,
				ISNULL(d.Winloss, 0)			AS Winloss,
				ISNULL(d.Bonus, 0)				AS Bonus,
				ISNULL(d.PlatFormFee, 0)		AS PlatFormFee,
				ISNULL(d.OperationalFee, 0)		AS OperationalFee,
				ISNULL(d.BankingFee, 0)			AS BankingFee,
				ISNULL(d.NetWinloss, 0)			AS NetWinloss,
				ISNULL(d.CommissionRate, 0)		AS CommissionRate,
				ISNULL(d.Commission, 0)			AS Commission,
				ROW_NUMBER() OVER(ORDER BY
					CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN ai.Username END ASC,
					CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN ai.Username END DESC,
					CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(d.Turnover, 0) END ASC,
					CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(d.Turnover, 0) END DESC,
					CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(d.Winloss, 0) END ASC,
					CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(d.Winloss, 0) END DESC,
					CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(d.Commission, 0) END ASC,
					CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(d.Commission, 0) END DESC)
												AS RowIdx
			FROM dbo.AffInfo ai WITH (NOLOCK)
				LEFT JOIN #AffData d ON ai.AffId = d.AffId
				LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			WHERE ai.Status = 'Approved'
				AND ai.Username LIKE '%' + @Username + '%'
				AND (@PreferredLanguage = '' OR ad.PreferredLanguage = @PreferredLanguage)
			) AS aff
		WHERE RowIdx BETWEEN @RowStart AND @RowEnd

		-- Statistics
		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME
		SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatistics1_bk WITH (NOLOCK)

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tempToDate	= @ToDate

			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM
			(
				SELECT
					a.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)) AS MonthDate,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT c.IP) AS UniqueClick
				FROM #AffInfo a
					INNER JOIN dbo.ClickStatistics1 c WITH (NOLOCK) ON a.AffId = c.AffId
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					a.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0))
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
					a.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)) AS MonthDate,
					c.IP,
					COUNT(1) AS TotalClick
				FROM #AffInfo a
					INNER JOIN dbo.ClickStatistics1_bk c WITH (NOLOCK) ON a.AffId = c.AffId
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					a.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)),
					c.IP
			) AS c
			GROUP BY AffId
		END
	END

	-- Return detail
	SELECT
		a.AffId,
		a.Username,
		ISNULL(s.TotalClick, 0) AS TotalClick,
		ISNULL(s.UniqueClick, 0) AS UniqueClick,
		ISNULL(su.Signup, 0) AS Signup,
		ISNULL(mi.FDM, 0) AS FDM,
		a.ActivePlayer AS ActiveMember,
		a.QualifiedMember AS QualifiedMember,
		a.Deposit AS Deposit,
		a.Withdrawal,
		a.Turnover,
		a.Winloss AS Winlost,
		a.Bonus,
		a.PlatFormFee,
		a.OperationalFee,
		a.BankingFee,
		a.PlatFormFee + a.OperationalFee + a.BankingFee AS TotalFee,
		a.CommissionRate,
		a.Commission AS Earning,
		ISNULL(at.AffWithdrawal, 0) AS AffWithdrawal,
		ISNULL(at.AffAdjustment, 0) AS AffAdjustment,
		ISNULL(at.BFF, 0) AS BFF
	FROM #AffPaging a
		LEFT JOIN (
			SELECT AffId, SUM(ISNULL(TotalClick, 0)) AS TotalClick, SUM(ISNULL(UniqueClick, 0)) AS UniqueClick FROM #Statistics GROUP BY AffId
		) s ON a.AffId = s.AffId
		LEFT JOIN #Signup su ON a.AffId = su.AffId
		LEFT JOIN (
			SELECT mi.AffId, COUNT(1) AS FDM
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
				)
			GROUP BY mi.AffId
		) mi ON a.AffId = mi.AffId
		LEFT JOIN (
			SELECT AffId,
				SUM(CASE WHEN TransType = 202 AND TransDate >= @FromDate THEN ABS(Amount) ELSE 0 END) AS AffWithdrawal,
				SUM(CASE WHEN TransType = 203 AND TransDate >= @FromDate THEN Amount ELSE 0 END) AS AffAdjustment,
				SUM(Amount) AS BFF
			FROM dbo.AffTrans WITH (NOLOCK)
			WHERE TransDate < DATEADD(DAY, 1, @ToDate)
				AND Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY AffId
		) at ON a.AffId = at.AffId
	ORDER BY a.RowIdx

	-- Return total
	SELECT
		SUM(ISNULL(s.TotalClick, 0)) AS TotalClick,
		SUM(ISNULL(s.UniqueClick, 0)) AS UniqueClick,
		SUM(ISNULL(su.Signup, 0)) AS Signup,
		SUM(ISNULL(mi.FDM, 0)) AS FDM,
		SUM(ISNULL(ad.ActivePlayer, 0)) AS ActiveMember,
		SUM(ISNULL(ad.QualifiedMember, 0)) AS QualifiedMember,
		SUM(ISNULL(ad.Deposit, 0)) AS Deposit,
		SUM(ISNULL(ad.Withdrawal, 0)) AS Withdrawal,
		SUM(ISNULL(ad.Turnover, 0)) AS Turnover,
		SUM(ISNULL(ad.Winloss, 0)) AS Winlost,
		SUM(ISNULL(ad.Bonus, 0)) AS Bonus,
		SUM(ISNULL(ad.PlatFormFee, 0)) AS PlatFormFee,
		SUM(ISNULL(ad.OperationalFee, 0)) AS OperationalFee,
		SUM(ISNULL(ad.BankingFee, 0)) AS BankingFee,
		SUM(ISNULL(ad.PlatFormFee, 0) + ISNULL(ad.OperationalFee, 0) + ISNULL(ad.BankingFee, 0)) AS TotalFee,
		0 AS CommissionRate,
		SUM(ISNULL(ad.Commission, 0)) AS Earning,
		SUM(ISNULL(at.AffWithdrawal, 0)) AS AffWithdrawal,
		SUM(ISNULL(at.AffAdjustment, 0)) AS AffAdjustment,
		SUM(ISNULL(at.BFF, 0)) AS BFF
	FROM #AffInfo a
		LEFT JOIN (
			SELECT AffId, SUM(ISNULL(TotalClick, 0)) AS TotalClick, SUM(ISNULL(UniqueClick, 0)) AS UniqueClick FROM #Statistics GROUP BY AffId
		) s ON a.AffId = s.AffId
		LEFT JOIN #AffData ad ON a.AffId = ad.AffId
		LEFT JOIN #Signup su ON a.AffId = su.AffId
		LEFT JOIN (
			SELECT mi.AffId, COUNT(1) AS FDM
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
				)
			GROUP BY mi.AffId
		) mi ON a.AffId = mi.AffId
		LEFT JOIN (
			SELECT AffId,
				SUM(CASE WHEN TransType = 202 AND TransDate >= @FromDate THEN ABS(Amount) ELSE 0 END) AS AffWithdrawal,
				SUM(CASE WHEN TransType = 203 AND TransDate >= @FromDate THEN Amount ELSE 0 END) AS AffAdjustment,
				SUM(Amount) AS BFF
			FROM dbo.AffTrans WITH (NOLOCK)
			WHERE TransDate < DATEADD(DAY, 1, @ToDate)
				AND Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY AffId
		) at ON a.AffId = at.AffId

	DROP TABLE #AffData
	DROP TABLE #AffInfo
	DROP TABLE #AffPaging
	DROP TABLE #Signup
	DROP TABLE #Statistics
END
GO