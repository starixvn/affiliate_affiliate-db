/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_Statistics_Sel] 
	@AffID		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Customer - Statistics

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT	@FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	SELECT	@ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	-- member statistics
	BEGIN
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
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= CONVERT(DATE, GETDATE())

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
			EXEC dbo.Aff_Commission_UnCalc @AffIds = 'all', @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate
		END

		-- Calculated Months
		BEGIN
			SELECT	@tempFromDate	= '1970-01-01',
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
			EXEC dbo.Aff_Commission_Calc @AffIds = 'all', @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate
		END
	END
	
	SELECT
		SUM(ISNULL(QualifiedMember, 0)) AS QualifiledMemberAll,
		SUM(ISNULL(ActivePlayer, 0))	AS ActivePlayerAll,
		SUM(ISNULL(Deposit, 0))			AS DepositAll,
		SUM(ISNULL(Turnover, 0))		AS TurnoverAll,
		SUM(ISNULL(Winloss, 0))			AS WinlossAll
	FROM #TempCommission
	WHERE ProductId = 0

	SELECT
		COUNT(1) AS TotalPlayer,
		COUNT(IBCCustID) AS TotalPlayerDepUp,
		COUNT(CASE WHEN creatdate >= @FromBeginMonth AND creatdate < @ToNextMonth THEN 1 ELSE NULL END) AS NewSignUp
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId

	SELECT COUNT(1) AS NewSignUpDep
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate >= @FromBeginMonth AND mi.CreatedDate < @ToNextMonth
		AND mi.AffId = @AffID
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.IBCCustID = mi.IBCCustID
				AND mr.RemovedDate >= @FromBeginMonth AND mr.RemovedDate < @ToNextMonth
		)

	SELECT
		SUM(UniqueClick)	AS TotalUniqueClicks,
		SUM(TotalClick)		AS TotalClicks
	FROM
	(
		SELECT s.Date, COUNT(DISTINCT s.IP) AS UniqueClick, COUNT(1) AS TotalClick
		FROM ClickStatistics s(NOLOCK)
			INNER JOIN TrackingCode a(NOLOCK) ON a.TrackingID = s.TrackingID
		WHERE s.Date >= @MonthDate AND a.AffID = @AffID
		GROUP BY s.Date

		UNION ALL
		SELECT Date, UniqueClick, TotalClick
		FROM ClickStatisticsSum(NOLOCK)
		WHERE AffID = @AffID
			AND TrackingID = 0
			AND IsForMonth = 1
			AND [date] >= @FromBeginMonth
			AND [date] < @ToNextMonth
	) AS A
	
	;WITH CTE_Device AS (
		SELECT DeviceType, SUM(TotalClick) AS TotalClicks, SUM(UniqueClick) AS UniqueClicks
		FROM (
			SELECT
				ISNULL(c.DeviceType, 0) AS DeviceType,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT c.IP) AS UniqueClick
			FROM dbo.ClickStatistics1 c WITH (NOLOCK)
			WHERE
				c.Date >= @FromBeginMonth AND c.Date < @ToNextMonth
				AND c.AffId = @AffId
			GROUP BY ISNULL(c.DeviceType, 0), c.Date

			UNION ALL
			SELECT
				ISNULL(c.DeviceType, 0) AS DeviceType,
				SUM(TotalClick) AS TotalClick,
				SUM(UniqueClick) AS UniqueClick
			FROM dbo.ClickStatistics1Sum c WITH (NOLOCK)
			WHERE
				c.Date >= @FromBeginMonth AND c.Date < @ToNextMonth
				AND c.AffId = @AffId
			GROUP BY ISNULL(c.DeviceType, 0), c.Date
		) AS A
		GROUP BY DeviceType
	)
	SELECT
		SUM(CASE WHEN DeviceType = 0 THEN ISNULL(TotalClicks, 0) ELSE 0 END) AS TotalClicksBySite,
		SUM(CASE WHEN DeviceType = 0 THEN ISNULL(UniqueClicks, 0) ELSE 0 END) AS TotalUniqueClicksBySite,
		SUM(CASE WHEN DeviceType = 1 THEN ISNULL(TotalClicks, 0) ELSE 0 END) AS TotalClicksByMobile,
		SUM(CASE WHEN DeviceType = 1 THEN ISNULL(UniqueClicks, 0) ELSE 0 END) AS TotalUniqueClicksByMobile
	FROM CTE_Device

	SELECT ISNULL(dbo.Aff_GetAffBalance(@AffID), 0) AS BalBroughtforward

	DROP TABLE #TempCommission
END
GO