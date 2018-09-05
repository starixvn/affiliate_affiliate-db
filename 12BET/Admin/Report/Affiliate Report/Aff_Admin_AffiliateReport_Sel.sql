/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@Username			NVARCHAR(50) = NULL,
	@FromDate			SMALLDATETIME,
	@ToDate				SMALLDATETIME,
	@IsGetAll			BIT = 0,
	@PreferredLanguage	VARCHAR(11) = NULL,
	@ProductIds			VARCHAR(MAX) = '0',
	@SortType			TINYINT = 1,
	@SortDirectionType	BIT = 0,
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

	Param's Explanation:
		- @SortType: 1: Affiliate username, 2: Turnover, 3: Winloss, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
*/

BEGIN
	SET NOCOUNT ON

	SELECT	@FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0), -- Begin Month of @FromDate
			@ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Month of @ToDate

	IF @IsGetAll = 1
	BEGIN
		SELECT @FromDate = DATEADD(DAY, 1, CONVERT(DATE, SValue))
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'AFF_OldReportDate'

		SELECT @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	END

	/*
		=============== Page ===============
	*/
	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
			@RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #AffInfo (RowIdx INT, AffId INT PRIMARY KEY, Username VARCHAR(50), NRows INT)
	
	IF @SortType = 1 -- Affiliate username
	BEGIN
		INSERT INTO #AffInfo (RowIdx, AffId, Username, NRows)
		SELECT RowIdx, AffId, Username, NRows
		FROM
		(
			SELECT ai.AffId, ai.Username,
				ROW_NUMBER() OVER(ORDER BY
									CASE WHEN @SortDirectionType = 0 THEN ai.Username END ASC,
									CASE WHEN @SortDirectionType = 1 THEN ai.Username END DESC) AS RowIdx,
				COUNT(1) OVER() AS NRows
			FROM dbo.AffInfo ai WITH (NOLOCK)
				LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			WHERE ai.Username LIKE '%' + ISNULL(@Username, '') + '%'
				AND ai.Status = 'Approved'
				AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage)
		) AS aff
		WHERE RowIdx BETWEEN @RowStart AND @RowEnd

		-- No data
		IF @@ROWCOUNT = 0
			RETURN

		SELECT TOP 1 @NRows = NRows FROM #AffInfo
	END

	/*
		=============== Get data ===============
	*/
	BEGIN
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
			Commission		MONEY
		)

		CREATE CLUSTERED INDEX IX_AffId ON #AffData (AffId)

		DECLARE @AffIds NVARCHAR(MAX)

		IF @SortType = 1
			SELECT @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), AffId) FROM #AffInfo
		ELSE
			SELECT @AffIds = 'all'

		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

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
			CommissionRate	DECIMAL(9,8),
			Commission		MONEY
		)

		-- Uncalculated Months
		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= @ToDate

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
			EXEC dbo.Aff_Commission_UnCalc @AffIds = @AffIds, @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate
		END

		-- Calculated Months
		IF @FromDate <= @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= @FromDate,
					@tempToDate		= @MaxCommDate

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
			EXEC dbo.Aff_Commission_Calc @AffIds = @AffIds, @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate
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
			Commission
		)
		SELECT
			AffId,
			SUM(ActivePlayer)		AS ActivePlayer,
			SUM(QualifiedMember)	AS QualifiedMember,
			SUM(Deposit)			AS Deposit,
			SUM(Withdrawal)			AS Withdrawal,
			SUM(Turnover)			AS Turnover,
			SUM(Winloss)			AS Winloss,
			SUM(Bonus)				AS Bonus,
			SUM(PlatFormFee)		AS PlatFormFee,
			SUM(OperationalFee)		AS OperationalFee,
			SUM(BankingFee)			AS BankingFee,
			SUM(NetWinloss)			AS NetWinloss,
			SUM(Commission)			AS Commission
		FROM #TempCommission
		WHERE ProductId = 0
		GROUP BY
			AffId

		IF @ProductIds <> '0'
		BEGIN
			UPDATE ad
			SET ad.Turnover = ISNULL(t.Turnover, 0),
				ad.Winloss = ISNULL(t.Winloss, 0)
			FROM #AffData ad
				LEFT JOIN (
					SELECT AffId, SUM(Turnover) AS Turnover, SUM(Winloss) AS Winloss
					FROM #TempCommission
					WHERE ProductId IN (SELECT val FROM dbo.Aff_f_StringSplit(@ProductIds, ','))
					GROUP BY AffId
				) t ON ad.AffId = t.AffId
			OPTION (MAXRECURSION 0)
		END

		DROP TABLE #TempCommission
	END

	IF @SortType <> 1
	BEGIN
		INSERT INTO #AffInfo (RowIdx, AffId, Username, NRows)
		SELECT RowIdx, AffId, Username, NRows
		FROM
		(
			SELECT ai.AffId, ai.Username,
				ROW_NUMBER() OVER(ORDER BY
									CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ISNULL(adt.Turnover, 0) END ASC,
									CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ISNULL(adt.Turnover, 0) END DESC,
									CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(adt.Winloss, 0) END ASC,
									CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(adt.Winloss, 0) END DESC,
									CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(adt.Commission, 0) END ASC,
									CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(adt.Commission, 0) END DESC) AS RowIdx,
				COUNT(1) OVER() AS NRows
			FROM dbo.AffInfo ai WITH (NOLOCK)
				LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
				LEFT JOIN (
					SELECT AffId, SUM(Turnover) AS Turnover, SUM(Winloss) AS Winloss, SUM(Commission) AS Commission
					FROM #AffData
					GROUP BY AffId
				) AS adt ON ai.AffId = adt.AffId
			WHERE ai.Username LIKE '%' + ISNULL(@Username, '') + '%'
				AND ai.Status = 'Approved'
				AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage)
		) AS aff
		WHERE RowIdx BETWEEN @RowStart AND @RowEnd

		-- No data
		IF @@ROWCOUNT = 0
			RETURN

		SELECT TOP 1 @NRows = NRows FROM #AffInfo
	END

	/*
		=============== Total Click, Unique Click, Signup, FDM ===============
	*/
	BEGIN
		DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		CREATE CLUSTERED INDEX CIX_AffId ON #Statistics (AffId)

		-- Click statistics
		DECLARE @ArchiveDate SMALLDATETIME
		SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatistics1_bk WITH (NOLOCK)

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tmpFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tmpToDate	= @ToDate

			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM
			(
				SELECT
					c.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT IP) AS UniqueClick
				FROM dbo.ClickStatistics1 c WITH (NOLOCK)
					INNER JOIN #AffInfo ai ON ai.AffId = c.AffId
				WHERE Date BETWEEN @tmpFromDate AND @tmpToDate
				GROUP BY
					c.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0))
			) AS A
			GROUP BY AffId
		END

		IF @FromDate <= @ArchiveDate
		BEGIN
			SELECT @tmpFromDate = @FromDate
			SELECT @tmpToDate	= CASE WHEN @ToDate > @ArchiveDate THEN @ArchiveDate ELSE @ToDate END

			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM
			(
				SELECT
					c.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT IP) AS UniqueClick
				FROM dbo.ClickStatistics1_bk c WITH (NOLOCK)
					INNER JOIN #AffInfo ai ON ai.AffId = c.AffId
				WHERE Date BETWEEN @tmpFromDate AND @tmpToDate
				GROUP BY
					c.AffId,
					DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0))
			) AS A
			GROUP BY AffId
		END

		-- Signup, FDM (first deposit)
		DECLARE @sql NVARCHAR(MAX)
		SELECT  @sql = 'SELECT a.AffId, a.Signup
						FROM OPENQUERY(DBDEPOSIT, ''SELECT AffiliateId AS AffId, COUNT(1) AS Signup FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
													WHERE creatdate >= ''''' + CONVERT(VARCHAR(10), @FromDate, 120) + ''''' AND
														creatdate < ''''' + + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120) + '''''
													GROUP BY AffiliateId'') AS a
							INNER JOIN #AffInfo ai ON ai.AffId = a.AffId'
		INSERT INTO #Statistics (AffId, Signup)
		EXEC (@sql)

		INSERT INTO #Statistics (AffId, Signup)
		SELECT mi.AffId, COUNT(1) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN #AffInfo ai ON ai.AffId = mi.AffId
		WHERE mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
			)
		GROUP BY mi.AffId
	END

	/*
		=============== Affiliate: Payment, Adjustment, BFF ===============
	*/
	BEGIN
		CREATE TABLE #AffStatistics (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY)
		
		CREATE CLUSTERED INDEX CIX_AffId ON #AffStatistics (AffId)
		
		INSERT INTO #AffStatistics (AffId, AffWithdrawal, AffAdjustment)
		SELECT
			at.AffId,
			SUM(CASE WHEN TransType = 202 THEN ABS(Amount) ELSE 0 END) AS AffWithdrawal,
			SUM(CASE WHEN TransType = 203 THEN Amount ELSE 0 END) AS AffAdjustment
		FROM dbo.AffTrans at WITH (NOLOCK)
			INNER JOIN #AffInfo ai ON ai.AffId = at.AffId
		WHERE TransDate >= @FromDate AND TransDate < DATEADD(DAY, 1, @ToDate)
			AND TransType IN (202,203)
			AND Status IN ('Pending', 'Approved', 'Completed')
		GROUP BY
			at.AffId

		INSERT INTO #AffStatistics (AffId, BFF)
		SELECT at.AffId, SUM(Amount) AS BFF
		FROM dbo.AffTrans at WITH (NOLOCK)
			INNER JOIN #AffInfo ai ON ai.AffId = at.AffId
		WHERE TransDate < DATEADD(DAY, 1, @ToDate)
			AND Status IN ('Pending', 'Approved', 'Completed')
		GROUP BY at.AffId
	END

	/*
		=============== Return data ===============
	*/
	
	
	SELECT
		ai.AffId,
		ai.Username,
		ISNULL(TotalClick, 0)		AS TotalClick,
		ISNULL(UniqueClick, 0)		AS UniqueClick,
		ISNULL(Signup, 0)			AS Signup,
		ISNULL(FDM, 0)				AS FDM,
		ISNULL(ActivePlayer, 0)		AS ActiveMember,
		ISNULL(QualifiedMember, 0)	AS QualifiedMember,
		ISNULL(Deposit, 0)			AS Deposit,
		ISNULL(Withdrawal, 0)		AS Withdrawal,
		ISNULL(Turnover, 0)			AS Turnover,
		ISNULL(Winloss, 0)			AS Winlost,
		ISNULL(Bonus, 0)			AS Bonus,
		ISNULL(PlatFormFee, 0)		AS PlatFormFee,
		ISNULL(OperationalFee, 0)	AS OperationalFee,
		ISNULL(BankingFee, 0)		AS BankingFee,
		ISNULL(PlatFormFee, 0)
		 + ISNULL(OperationalFee, 0)
		 + ISNULL(BankingFee, 0)	AS TotalFee,
		ISNULL(
			CASE WHEN NetWinloss - Bonus = 0 THEN 0
				ELSE Commission/(NetWinloss - Bonus) END
			, 0)					AS CommissionRate,
		ISNULL(Commission, 0)		AS Earning,
		ISNULL(AffWithdrawal, 0)	AS AffWithdrawal,
		ISNULL(AffAdjustment, 0)	AS AffAdjustment,
		ISNULL(BFF, 0)				AS BFF
	FROM #AffInfo ai WITH (NOLOCK)
		LEFT JOIN #AffData ad ON ai.AffId = ad.AffId
		LEFT JOIN (
			SELECT AffId, SUM(AffWithdrawal) AS AffWithdrawal, SUM(AffAdjustment) AS AffAdjustment, SUM(BFF) AS BFF
			FROM #AffStatistics
			GROUP BY AffId
		) ast ON ai.AffId = ast.AffId
		LEFT JOIN (
			SELECT AffId, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick, SUM(Signup) AS Signup, SUM(FDM) AS FDM
			FROM #Statistics
			GROUP BY AffId
		) s ON ai.AffId = s.AffId

	DROP TABLE #Statistics
	DROP TABLE #AffStatistics
	DROP TABLE #AffData
	DROP TABLE #AffInfo
END
GO