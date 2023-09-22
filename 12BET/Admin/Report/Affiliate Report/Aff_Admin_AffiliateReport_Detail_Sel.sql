/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Detail_Sel]
	@Username			NVARCHAR(50),
	@FromDate			SMALLDATETIME,
	@ToDate				SMALLDATETIME,
	@IsGetAll			BIT = 0,
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
		- 20191101@Percy: Fix wrong FDM value [RedmineID: #123134]
		- 20200731@Percy: Change way to input Language [RedmineID: #121975]
		- 20220831@Eddie: Add new column 'Previous month's balance B/F' [RedmineID: #177178]
		- 20210528@Malcolm: Get data daily [RedmineID: #149210]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]

	Param's Explanation:
		- @SortType: 1: Month, 2: Turnover, 3: Winloss, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT  @Username = ISNULL(LTRIM(RTRIM(@Username)), '')

	DECLARE @AffId INT
	SELECT  @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE Username = @Username AND Status = 'Approved'

	IF @AffId IS NULL
		RETURN

	DECLARE @MinReportDate SMALLDATETIME, @EndOfCurrentMonth SMALLDATETIME
	SELECT  @MinReportDate		= dbo.Aff_f_GetMinReportDate(0)
	SELECT  @EndOfCurrentMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	IF @IsGetAll = 0
	BEGIN
		IF @FromDate IS NULL OR @ToDate IS NULL
			RETURN

		SELECT  @FromDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0) -- Begin Of Month
		SELECT  @ToDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Of Month

		IF @FromDate < @MinReportDate
			SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MinReportDate), 0)

		IF @ToDate > @EndOfCurrentMonth
			SELECT @ToDate = @EndOfCurrentMonth
	END
	ELSE
	BEGIN
		SELECT  @FromDate	= @MinReportDate
		SELECT  @ToDate		= @EndOfCurrentMonth
	END

	SELECT @NRows = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NRows <= 0
		RETURN

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, RowIdx INT)
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
	DROP TABLE IF EXISTS #TempCommission
	DROP TABLE IF EXISTS #Signup
	DROP TABLE IF EXISTS #Statistics

	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

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
			Commission				MONEY,
			-----FDM & Bonus
			IsApplyBonus			BIT,
			FDMCount				INT,
			FDMDeposit				MONEY,
			FDMCommissionRate		DECIMAL(9, 8),
			FDMCommission			MONEY
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
				Commission,
				---FDM & Bonus
				IsApplyBonus,		
				FDMCount,			
				FDMDeposit,			
				FDMCommissionRate,
				FDMCommission
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@IsSumAll			= 0,
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
				Commission,
				---FDM & Bonus
				IsApplyBonus,		
				FDMCount,			
				FDMDeposit,			
				FDMCommissionRate,
				FDMCommission
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= @ProductIds,
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1
		END

		-- Signup
		CREATE TABLE #Signup (MonthDate SMALLDATETIME, Signup INT)

		DECLARE @sql NVARCHAR(MAX)
		SELECT  @sql = 'SELECT a.MonthDate, a.Signup
						FROM OPENQUERY(DBDEPOSIT, ''SELECT
														DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, creatdate) + 1, 0)) AS MonthDate,
														COUNT(1) AS Signup FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
													WHERE AffiliateId = ' + @AffIds + ' AND creatdate >= ''''' + CONVERT(VARCHAR(10), @FromDate, 120) + ''''' AND
														creatdate < ''''' + + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120) + '''''
													GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, creatdate) + 1, 0))'') AS a'
		INSERT INTO #Signup (MonthDate, Signup)
		EXEC (@sql)

		-- Statistics
		CREATE TABLE #Statistics (MonthDate SMALLDATETIME, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME
		SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatistics1_bk WITH (NOLOCK)

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tempToDate	= @ToDate

			INSERT INTO #Statistics (MonthDate, TotalClick, UniqueClick)
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)) AS MonthDate,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT c.IP) AS UniqueClick
			FROM dbo.ClickStatistics1 c WITH (NOLOCK)
			WHERE c.AffId = @AffId
				AND c.Date BETWEEN @tempFromDate AND @tempToDate
			GROUP BY
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0))
		END

		IF @FromDate <= @ArchiveDate
		BEGIN
			SELECT @tempFromDate = @FromDate
			SELECT @tempToDate	= CASE WHEN @ToDate > @ArchiveDate THEN @ArchiveDate ELSE @ToDate END
			
			INSERT INTO #Statistics (MonthDate, TotalClick, UniqueClick)
			SELECT MonthDate, SUM(TotalClick), COUNT(1) AS UniqueClick
			FROM
			(
				SELECT
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)) AS MonthDate,
					c.IP,
					COUNT(1) AS TotalClick
				FROM dbo.ClickStatistics1_bk c WITH (NOLOCK)
				WHERE c.AffId = @AffId
					AND c.Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, c.Date) + 1, 0)),
					c.IP
			) AS c
			GROUP BY MonthDate
		END
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

		;WITH CTE_RowNum AS
		(
			SELECT md.MonthDate, ROW_NUMBER() OVER(ORDER BY
							CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN md.MonthDate END ASC,
							CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN md.MonthDate END DESC,
							CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(tc.Turnover, 0) END ASC,
							CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(tc.Turnover, 0) END DESC,
							CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(tc.Winloss, 0) END ASC,
							CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(tc.Winloss, 0) END DESC,
							CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(tc.Commission, 0) END ASC,
							CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(tc.Commission, 0) END DESC) AS RowIdx
			FROM @MonthDate md
				LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		)
		UPDATE md
		SET md.RowIdx = rn.RowIdx
		FROM @MonthDate md
			INNER JOIN CTE_RowNum rn ON md.MonthDate = rn.MonthDate
	END

	DECLARE @PreviousFromDate	SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0))
	
	DECLARE @tblAffStatistics TABLE (MonthDate SMALLDATETIME, AffWithdrawal MONEY, AffAdjustment MONEY, PreviousBFF MONEY, BFF MONEY)
	
	;WITH Pre_MonthDate as (
		SELECT MonthDate
		FROM @MonthDate
		UNION ALL
		SELECT @PreviousFromDate
	)
	INSERT INTO @tblAffStatistics (MonthDate, AffWithdrawal, AffAdjustment, PreviousBFF, BFF)
	SELECT md.MonthDate, ISNULL(at.AffWithdrawal, 0), ISNULL(at.AffAdjustment, 0), 0, ISNULL(at.BFF, 0)
	FROM Pre_MonthDate md
		LEFT JOIN (
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE WHEN TransDate < @PreviousFromDate THEN @PreviousFromDate ELSE TransDate END) + 1, 0)) AS MonthDate,
				SUM(CASE WHEN TransType = 202 AND TransDate >= @PreviousFromDate THEN ABS(Amount) ELSE 0 END) AS AffWithdrawal,
				SUM(CASE WHEN TransType = 203 AND TransDate >= @PreviousFromDate THEN Amount ELSE 0 END) AS AffAdjustment,
				SUM(Amount) AS BFF
			FROM dbo.AffTrans WITH (NOLOCK)
			WHERE AffId = @AffId
				AND TransDate < DATEADD(DAY, 1, @ToDate)
				AND Status IN ('Pending', 'Approved', 'Completed')
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, CASE WHEN TransDate < @PreviousFromDate THEN @PreviousFromDate ELSE TransDate END) + 1, 0))
		) AS at ON md.MonthDate = at.MonthDate

	UPDATE md1
	SET md1.BFF = ISNULL(md.BFF, 0)
	FROM @tblAffStatistics md1
		CROSS APPLY (SELECT SUM(md2.BFF) AS BFF FROM @tblAffStatistics md2 WHERE md2.MonthDate <= md1.MonthDate) AS md
		
	UPDATE md1
	SET md1.PreviousBFF = ISNULL(md2.BFF, 0)
	FROM @tblAffStatistics md1
		INNER JOIN @tblAffStatistics md2 ON md2.MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md1.MonthDate), 0))
	
	-- Return detail
	SELECT
		md.MonthDate,
		CASE
			WHEN md.MonthDate >= GETDATE() THEN 'Temporary'
			WHEN md.MonthDate > @MaxCommDate THEN 'Uncalculated'
			ELSE '' END AS Description,
		ISNULL(s.TotalClick, 0)			AS TotalClick,
		ISNULL(s.UniqueClick, 0)		AS UniqueClick,
		ISNULL(su.Signup, 0)			AS Signup,
		ISNULL(mi.FDM, 0)				AS FDM,
		ISNULL(tc.ActivePlayer, 0)		AS ActiveMember,
		ISNULL(tc.QualifiedMember, 0)	AS QualifiedMember,
		ISNULL(tc.Deposit, 0)			AS Deposit,
		ISNULL(tc.Withdrawal, 0)		AS Withdrawal,
		ISNULL(tc.Turnover, 0)			AS Turnover,
		ISNULL(tc.Winloss, 0)			AS Winlost,
		ISNULL(tc.Bonus, 0)				AS Bonus,
		ISNULL(tc.PlatFormFee, 0)		AS PlatFormFee,
		ISNULL(tc.OperationalFee, 0)	AS OperationalFee,
		ISNULL(tc.BankingFee, 0)		AS BankingFee,
		ISNULL(tc.PlatFormFee + tc.OperationalFee + tc.BankingFee, 0) AS TotalFee,
		ISNULL(tc.CommissionRate, 0)	AS CommissionRate,
		ISNULL(tc.Commission, 0)		AS Earning,
		ISNULL(at.AffWithdrawal, 0)		AS AffWithdrawal,
		ISNULL(at.AffAdjustment, 0)		AS AffAdjustment,
		ISNULL(at.PreviousBFF, 0)				AS PreviousBFF,
		ISNULL(at.BFF, 0)				AS BFF,
		ISNULL(tc.FDMCommissionRate, 0)	AS FDMCommissionRate,
		ISNULL(tc.FDMCommission, 0)		AS FDMEarning
	FROM @MonthDate md
		LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		LEFT JOIN (
			SELECT MonthDate, SUM(ISNULL(TotalClick, 0)) AS TotalClick, SUM(ISNULL(UniqueClick, 0)) AS UniqueClick FROM #Statistics GROUP BY MonthDate
		) s ON md.MonthDate = s.MonthDate
		LEFT JOIN #Signup su ON md.MonthDate = su.MonthDate
		LEFT JOIN (
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, mi.CreatedDate) + 1, 0)) AS MonthDate, COUNT(1) AS FDM
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE mi.AffId = @AffId
				AND mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mi.IBCCustID = mr.IBCCustID
						AND mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
				)
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, mi.CreatedDate) + 1, 0))
		) mi ON md.MonthDate = mi.MonthDate
		LEFT JOIN @tblAffStatistics at ON md.MonthDate = at.MonthDate
	WHERE md.RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY md.RowIdx

	-- Return total
	SELECT
		SUM(ISNULL(s.TotalClick, 0)) AS TotalClick,
		SUM(ISNULL(s.UniqueClick, 0)) AS UniqueClick,
		SUM(ISNULL(su.Signup, 0)) AS Signup,
		SUM(ISNULL(mi.FDM, 0)) AS FDM,
		SUM(ISNULL(tc.ActivePlayer, 0)) AS ActiveMember,
		SUM(ISNULL(tc.QualifiedMember, 0)) AS QualifiedMember,
		SUM(ISNULL(tc.Deposit, 0)) AS Deposit,
		SUM(ISNULL(tc.Withdrawal, 0)) AS Withdrawal,
		SUM(ISNULL(tc.Turnover, 0)) AS Turnover,
		SUM(ISNULL(tc.Winloss, 0)) AS Winlost,
		SUM(ISNULL(tc.Bonus, 0)) AS Bonus,
		SUM(ISNULL(tc.PlatFormFee, 0)) AS PlatFormFee,
		SUM(ISNULL(tc.OperationalFee, 0)) AS OperationalFee,
		SUM(ISNULL(tc.BankingFee, 0)) AS BankingFee,
		SUM(ISNULL(tc.PlatFormFee, 0) + ISNULL(tc.OperationalFee, 0) + ISNULL(tc.BankingFee, 0)) AS TotalFee,
		AVG(ISNULL(tc.CommissionRate, 0)) AS CommissionRate,
		SUM(ISNULL(tc.Commission, 0)) AS Earning,
		SUM(ISNULL(at.AffWithdrawal, 0)) AS AffWithdrawal,
		SUM(ISNULL(at.AffAdjustment, 0)) AS AffAdjustment,
		SUM(ISNULL(CASE WHEN md.MonthDate = @ToDate THEN at.PreviousBFF ELSE 0 END, 0)) AS PreviousBFF, -- Previous of BFF
		SUM(ISNULL(CASE WHEN md.MonthDate = @ToDate THEN at.BFF ELSE 0 END, 0)) AS BFF -- the last month by running total
		,AVG(ISNULL(tc.FDMCommissionRate, 0)) AS FDMCommissionRate,
		SUM(ISNULL(tc.FDMCommission, 0)) AS FDMEarning
	FROM @MonthDate md
		LEFT JOIN #TempCommission tc ON md.MonthDate = tc.MonthDate
		LEFT JOIN (
			SELECT MonthDate, SUM(ISNULL(TotalClick, 0)) AS TotalClick, SUM(ISNULL(UniqueClick, 0)) AS UniqueClick FROM #Statistics GROUP BY MonthDate
		) s ON md.MonthDate = s.MonthDate
		LEFT JOIN #Signup su ON md.MonthDate = su.MonthDate
		LEFT JOIN (
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, mi.CreatedDate) + 1, 0)) AS MonthDate, COUNT(1) AS FDM
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE mi.AffId = @AffId
				AND mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mi.IBCCustID = mr.IBCCustID
						AND mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
				)
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, mi.CreatedDate) + 1, 0))
		) mi ON md.MonthDate = mi.MonthDate
		LEFT JOIN @tblAffStatistics at ON md.MonthDate = at.MonthDate
END
GO