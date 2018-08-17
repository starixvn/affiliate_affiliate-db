/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_StatisticsSel] 
	@AffID INT
	,@MonthDate SMALLDATETIME
	,@TotalQualifiedMembers INT OUTPUT
	,@TotalQualifiedCasino INT = 0 OUTPUT
	,@TotalQualifiedMembersHR INT OUTPUT
	,@TotalActivePlayer INT OUTPUT
	,@TotalPlayerDepUp INT OUTPUT
	,@TotalPlayer INT OUTPUT
	,@NewSignUpDep INT OUTPUT
	,@NewSignUp INT OUTPUT
	,@BalBroughtforward MONEY = 0 OUTPUT
	,@TotalDeposit MONEY OUTPUT
	,@TotalDepositUp MONEY OUTPUT
	,@TotalTurnover MONEY OUTPUT
	,@TotalTurnoverUp MONEY OUTPUT
	,@TotalWinlostUp MONEY OUTPUT
	,@TotalWinlost MONEY OUTPUT
	,@TotalUniqueClicks INT = 0 OUTPUT
	,@TotalClicks INT = 0 OUTPUT
	,@TotalUniqueClicksBySite INT = 0 OUTPUT -- Is PC / Laptop
	,@TotalClicksBySite INT = 0 OUTPUT -- Is PC / Laptop
	,@TotalUniqueClicksByMobile INT = 0 OUTPUT
	,@TotalClicksByMobile INT = 0 OUTPUT
AS

/*
	Created: 20090325@VinhTrinh
	Task : Get statistics for affiliate
	DB: DBAFF12BET.Affiliate_12BET
	Original : [Aff_CustomerSelStatistics]

	Revisions:
		- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).
		- 20090827@DungTong: Convert to new DB version
		- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"
		- 20101228@Henry: change bettype to new range
		- 20120507@Johnny: Get Casino qualified Active players
		- 20120606@Peter : Exclude waiting tickets 
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20140801@Bobby:  Update MemberClickStatistics
		- 20141218@Bobby: Update SS's bettype
		- 20170214@Percy: Fix FDM/Signup issue [RedmineID: #70507]
		- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]
		- 20180601@Percy: Refactor code for new change [RedmineID: #87923]

	Param's Explanation:
		• @AffID : Affiliate custid
		• @MonthDate : Date search(format:first day of the month).
		• @TotalActivePlayer : Get Active player in Month
		• @TotalPlayerDepUp int OUTPUT,--Get player deposited in our system
		• @NewSignUpDep : Get new signups of the month
		• @TotalDeposit : total deposit money for month search
		• @TotalDepositUp money OUTPUT,--total deposit money up to now
		• @TotalTurnover money OUTPUT,--total turnover money up to now
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

	-- Will remove later
	SELECT @TotalQualifiedCasino = 0, @TotalQualifiedMembersHR = 0
	
	SELECT
		@TotalQualifiedMembers = SUM(ISNULL(QualifiedMember, 0)),
		@TotalActivePlayer = SUM(ISNULL(ActivePlayer, 0)),
		@TotalDepositUp = SUM(ISNULL(Deposit, 0)),
		@TotalTurnoverUp = SUM(ISNULL(Turnover, 0)),
		@TotalWinlostUp = SUM(ISNULL(Winloss, 0))
	FROM #TempCommission
	WHERE ProductId = 0

	SELECT
		@TotalDepositUp = SUM(ISNULL(Deposit, 0)),
		@TotalTurnoverUp = SUM(ISNULL(Turnover, 0)),
		@TotalWinlostUp = SUM(ISNULL(Winloss, 0))
	FROM #TempCommission
	WHERE ProductId = 0 AND MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	SELECT
		@TotalPlayer = COUNT(1),
		@TotalPlayerDepUp = COUNT(IBCCustID),
		@NewSignUp = COUNT(CASE WHEN creatdate >= @FromBeginMonth AND creatdate < @ToNextMonth THEN 1 ELSE NULL END)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId

	SELECT
		@NewSignUpDep = COUNT(1)
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
		@TotalUniqueClicks = SUM(UniqueClick),
		@TotalClicks = SUM(TotalClick)
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
		@TotalClicksBySite			= SUM(CASE WHEN DeviceType = 0 THEN ISNULL(TotalClicks, 0) ELSE 0 END),
		@TotalUniqueClicksBySite	= SUM(CASE WHEN DeviceType = 0 THEN ISNULL(UniqueClicks, 0) ELSE 0 END),
		@TotalClicksByMobile		= SUM(CASE WHEN DeviceType = 1 THEN ISNULL(TotalClicks, 0) ELSE 0 END),
		@TotalUniqueClicksByMobile	= SUM(CASE WHEN DeviceType = 1 THEN ISNULL(UniqueClicks, 0) ELSE 0 END)
	FROM CTE_Device

	SELECT @BalBroughtforward = ISNULL(dbo.Aff_GetAffBalance(@AffID), 0)

	DROP TABLE #TempCommission
END
GO