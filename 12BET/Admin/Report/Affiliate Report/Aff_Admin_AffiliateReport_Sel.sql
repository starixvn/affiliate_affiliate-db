/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@AffType			SMALLINT = NULL,
	@Username			NVARCHAR(50) = NULL,
	@FromDate			SMALLDATETIME,
	@ToDate				SMALLDATETIME,
	@IsGetAll			BIT = 0,
	@PreferredLanguage	VARCHAR(11) = NULL,
	@SportId			INT = NULL,
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
*/

BEGIN
	SET NOCOUNT ON

	SELECT @SportId = ISNULL(@SportId, 0)

	SELECT	@FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0), -- Begin Month of @FromDate
			@ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Month of @ToDate

	IF @IsGetAll = 1
	BEGIN
		SELECT @FromDate = DATEADD(DAY, 1, CONVERT(DATE, SValue))
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'AFF_OldReportDate'

		SELECT @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	END

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
			@RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #AffData
	(
		RowIDX			INT,
		AffId			INT PRIMARY KEY,
		Username		NVARCHAR(50),
		TotalClick		INT,
		UniqueClick		INT,
		Signup			INT,
		FDM				INT,
		ActivePlayer	INT,
		QualifiedMember	INT,
		Deposit			MONEY,
		Withdrawal		MONEY,
		BankingFee		MONEY,
		Bonus			MONEY,
		Adjustment		MONEY,
		Turnover		MONEY,
		Winloss			MONEY,
		AffCommission	MONEY,
		AffWithdrawal	MONEY,
		AffAdjustment	MONEY,
		BFF				MONEY,
		NRows			INT
	)

	CREATE NONCLUSTERED INDEX IX_AffId ON #AffData (AffId)

	-- Get Affiliate Information
	BEGIN
		INSERT INTO #AffData
		(
			RowIDX,
			AffId,
			UserName,
			NRows
		)
		SELECT
			RowNum,
			AffId,
			UserName,
			NRows
		FROM
		(
			SELECT ai.AffId, ad.UserName, COUNT(1) OVER() AS NRows, ROW_NUMBER() OVER(ORDER BY ai.AffId ASC) AS RowNum
			FROM dbo.AffInfo ai WITH (NOLOCK)
				LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			WHERE ai.Status = 'Approved'
				AND (@AffType IS NULL OR ai.AffType = @AffType)
				AND ai.UserName LIKE '%' + ISNULL(@Username, '') + '%'
				AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage	= @PreferredLanguage)
		) AS A
		WHERE A.RowNum BETWEEN @RowStart AND @RowEnd
	
		SELECT TOP 1 @NRows = NRows FROM #AffData
	END

	-- Total/Unique Click, Signup, FDM
	BEGIN
		DECLARE @SumClickStatisticsDate SMALLDATETIME
		SELECT  @SumClickStatisticsDate = MAX(Date) FROM dbo.ClickStatistics1Sum WITH (NOLOCK)

		UPDATE ad
		SET ad.TotalClick = b.TotalClick,
			ad.UniqueClick = b.UniqueClick
		FROM #AffData ad
			CROSS APPLY (
				SELECT AffId, COUNT(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
				FROM
				(
					SELECT c.AffId, c.IP
					FROM dbo.ClickStatistics1 c WITH (NOLOCK)
					WHERE c.Date > @SumClickStatisticsDate AND c.Date < DATEADD(DAY, 1, @ToDate)
						AND c.AffId = ad.AffId
					UNION ALL
					SELECT c.AffId, c.IP
					FROM dbo.ClickStatistics1_bk c WITH (NOLOCK)
					WHERE c.Date >= @FromDate AND c.Date < DATEADD(DAY, 1, @SumClickStatisticsDate)
						AND c.AffId = ad.AffId
				) AS c
				GROUP BY AffId
			) AS b

		UPDATE ad
		SET ad.FDM = b.FDM
		FROM #AffData ad
			CROSS APPLY (
				SELECT COUNT(1) AS FDM
				FROM dbo.MemberInfo mi WITH (NOLOCK)
				WHERE mi.AffId = ad.AffId
					AND mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
					)
			) AS b
	
		DECLARE @Signup TABLE (AffId INT, Signup INT)

		DECLARE @sql NVARCHAR(MAX)
		SELECT  @sql = 'SELECT ad.AffId, COUNT(1) AS Signup
						FROM OPENQUERY(DBDEPOSIT, ''SELECT AffiliateId AS AffId FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
													WHERE creatdate >= ''''' + CONVERT(VARCHAR(10), @FromDate, 120) + ''''' AND
														creatdate < ''''' + + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120) + ''''''') AS a
							INNER JOIN #AffData ad ON a.AffId = ad.AffId
						GROUP BY ad.AffId'

		INSERT INTO @Signup (AffId, Signup)
		EXEC (@sql)

		UPDATE ad
		SET ad.Signup = s.Signup
		FROM #AffData ad
			INNER JOIN @Signup s ON ad.AffId = s.AffId
	END
	
	-- Get data winloss
	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), AffId) FROM #AffData

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
			
		UPDATE ad
		SET ad.ActivePlayer		= tc.ActivePlayer,
			ad.QualifiedMember	= tc.QualifiedMember,
			ad.Deposit			= tc.Deposit,
			ad.Withdrawal		= tc.Withdrawal,
			ad.BankingFee		= tc.BankingFee,
			ad.Bonus			= tc.Bonus,
			ad.Turnover			= tc.Turnover,
			ad.Winloss			= tc.Winloss,
			ad.BFF				= tc.Commission
		FROM #AffData ad
			INNER JOIN (
				SELECT
					AffId,
					SUM(ActivePlayer)		AS ActivePlayer,
					SUM(QualifiedMember)	AS QualifiedMember,
					SUM(Deposit)			AS Deposit,
					SUM(Withdrawal)			AS Withdrawal,
					SUM(BankingFee)			AS BankingFee,
					SUM(Bonus)				AS Bonus,
					SUM(Turnover)			AS Turnover,
					SUM(Winloss)			AS Winloss,
					SUM(Commission)			AS Commission
				FROM #TempCommission
				WHERE ProductId = 0
				GROUP BY
					AffId
			) AS tc ON ad.AffId = tc.AffId
	END

	-- Affiliate: Commission, Payment, Adjustment, BFF
	BEGIN
		;WITH CTE_MonthDate AS
		(
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromDate)) AS MonthDate
			UNION ALL
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
			FROM CTE_MonthDate
			WHERE MonthDate < @ToDate
		)
		UPDATE ad
		SET ad.AffCommission	= ISNULL(c.Commission, 0),
			ad.AffWithdrawal	= ISNULL(t.Payment, 0),
			ad.AffAdjustment	= ISNULL(t.Adjustment, 0),
			ad.BFF				= ISNULL(ad.BFF, 0) + ISNULL(c.Commission, 0) - ISNULL(t.Payment, 0) + ISNULL(t.Adjustment, 0)
		FROM #AffData ad
			CROSS APPLY (
				SELECT
					SUM(at.Amount) AS Commission
				FROM dbo.AffTrans at WITH (NOLOCK)
					CROSS APPLY CTE_MonthDate md
				WHERE at.AffId = ad.AffId AND at.TransDate = md.MonthDate
					AND at.TransType = 201
			) AS c
			CROSS APPLY (
				SELECT
					SUM(CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE 0 END) AS Payment,
					SUM(CASE WHEN at.TransType = 203 THEN at.Amount ELSE 0 END) AS Adjustment
				FROM dbo.AffTrans at WITH (NOLOCK)
				WHERE at.AffId = ad.AffId
					AND at.TransDate >= @FromDate AND at.TransDate < DATEADD(DAY, 1, @ToDate)
					AND at.TransType IN (202,203)
					AND at.Status IN ('Pending', 'Approved', 'Completed')
			) AS t
		OPTION (MAXRECURSION 0)
	END

	-- Return data
	SELECT
		RowIDX,
		AffId,
		UserName,
		ISNULL(Deposit, 0) AS Deposit,
		ISNULL(Withdrawal, 0) AS Withdrawal,
		ISNULL(Turnover, 0) AS Turnover,
		ISNULL(Winloss, 0) AS Winlost,
		ISNULL(Bonus, 0) AS Bonus,
		ISNULL(BankingFee, 0) AS PSP,
		0 AS Adjustment, -- will remove later
		ISNULL(AffAdjustment, 0) AS AffAdjustment,
		ISNULL(AffWithdrawal, 0) AS AffWithdrawal,
		ISNULL(BFF, 0) AS AffBF,
		ISNULL(TotalClick, 0) AS OldTotalClick,
		ISNULL(UniqueClick, 0) AS OldUniqueClick,
		ISNULL(TotalClick, 0) AS NewTotalClick,
		ISNULL(UniqueClick, 0) AS NewUniqueClick,
		ISNULL(FDM, 0) AS TotalFDM,
		ISNULL(Signup, 0) AS TotalSignup,
		ISNULL(ActivePlayer, 0) AS TotalActiveMember,
		ISNULL(QualifiedMember, 0) AS TotalQualifiedMember
	FROM #AffData

	DROP TABLE #TempCommission
	DROP TABLE #AffData
END
GO