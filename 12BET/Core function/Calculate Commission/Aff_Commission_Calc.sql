/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Commission_Calc]
	@AffIds			VARCHAR(MAX) = 'all',
	@FromMonthDate	SMALLDATETIME,
	@ToMonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core SP - Calculate commission for months which are calculated

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CutOffDate SMALLDATETIME, @n INT = 2147483647 -- max int
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tempFromMonth SMALLDATETIME, @tempToMonth SMALLDATETIME
	SELECT  @tempFromMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0))
	SELECT  @tempToMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))

	DECLARE @tempFrom SMALLDATETIME, @tempTo SMALLDATETIME

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME, AffId INT, GroupId INT)

	CREATE TABLE #AffCommission
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
		NetWinloss		MONEY,
		ActivePlayer	INT,
		QualifiedMember INT,
		QMTurnover		MONEY,
		CommissionRate	DECIMAL(9,8),
		Commission		MONEY
	)

	IF @tempToMonth > @CutOffDate
	BEGIN
		SELECT @tempFrom = CASE WHEN @tempFromMonth <= @CutOffDate THEN DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @CutOffDate) + 2, 0)) ELSE @tempFromMonth END
		SELECT @tempTo = @tempToMonth

		IF @AffIds = 'all'
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT @tempFrom AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate)
			SELECT MonthDate FROM CTE_MonthDate
			OPTION (MAXRECURSION 0)

			INSERT INTO #AffCommission
			(
				MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss,
				NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate,Commission
			)
			SELECT
				dt.MonthDate,dt.AffId,dt.GroupId,dt.ProductId,dt.Deposit,dt.Withdrawal,dt.Bonus,dt.Turnover,dt.Winloss,
				dt.NetWinloss,dt.ActivePlayer,dt.QualifiedMember,dt.QMTurnover,dt.CommissionRate,dt.NetWinloss*dt.CommissionRate AS Commission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss,
						NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate
					FROM dbo.rptAffCommission ac WITH (NOLOCK)
					WHERE ac.MonthDate = md.MonthDate
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))
		END
		ELSE
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT @tempFrom AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT MonthDate, val AS AffId FROM CTE_MonthDate CROSS JOIN dbo.Aff_f_StringSplit(@AffIds, ',') f
			OPTION (MAXRECURSION 0)

			INSERT INTO #AffCommission
			(
				MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss,
				NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate,Commission
			)
			SELECT
				dt.MonthDate,dt.AffId,dt.GroupId,dt.ProductId,dt.Deposit,dt.Withdrawal,dt.Bonus,dt.Turnover,dt.Winloss,
				dt.NetWinloss,dt.ActivePlayer,dt.QualifiedMember,dt.QMTurnover,dt.CommissionRate,dt.NetWinloss*dt.CommissionRate AS Commission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss,
						NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate
					FROM dbo.rptAffCommission ac WITH (NOLOCK)
					WHERE ac.MonthDate = md.MonthDate
						AND ac.AffId = md.AffId
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))
		END
	END

	IF @tempFromMonth <= @CutOffDate
	BEGIN
		DELETE @MonthDate

		SELECT @tempFrom = @tempFromMonth
		SELECT @tempTo = CASE WHEN @tempToMonth > @CutOffDate THEN @CutOffDate ELSE @tempToMonth END

		DECLARE @tempData TABLE
		(
			MonthDate SMALLDATETIME, AffId INT, GroupId INT, ProductId INT, Deposit MONEY, Withdrawal MONEY, Bonus MONEY, Turnover MONEY, Winloss MONEY,
			NetWinloss MONEY, ActivePlayer INT, QualifiedMember INT, CommissionRate DECIMAL(9,8), Commission MONEY
		)

		IF @AffIds = 'all'
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT @tempFrom AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate)
			SELECT MonthDate FROM CTE_MonthDate
			OPTION (MAXRECURSION 0)

			INSERT INTO @tempData
			(
				MonthDate,AffId,GroupId,ProductId,Deposit,Bonus,Turnover,Winloss,
				NetWinloss,QualifiedMember,CommissionRate,Commission
			)
			SELECT
				dt.MonthDate,dt.AffId,dt.GroupId,dt.ProductId,dt.Deposit,dt.Bonus,dt.Turnover,dt.Winloss,
				dt.NetWinloss,dt.QualifiedMember,dt.CommissionRate,dt.Commission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						MonthDate,AffId,GroupId,SportId AS ProductId,MemberDeposit AS Deposit,MemberBonus AS Bonus,MemberTurnover AS Turnover,MemberWinlost AS Winloss,
						(AffWinlost+MemberBonus) AS NetWinloss,QualifiedMember,Commission AS CommissionRate,AffWinlost*Commission AS Commission
					FROM dbo.AffCommission ac WITH (NOLOCK)
					WHERE ac.WinlostDate = md.MonthDate
						AND (ac.MemberDeposit > 0 OR ac.MemberTurnover > 0)
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))

			INSERT INTO @tempData (MonthDate,AffId,GroupId,ProductId,Withdrawal)
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate,AffId,0,0,SUM(MemWithdrawal) AS Withdrawal
			FROM dbo.AffDailySummary WITH (NOLOCK)
			WHERE WinlostDate BETWEEN DATEADD(MONTH, -1, DATEADD(DAY, 1, @tempFromMonth)) AND @tempToMonth
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)),AffId
			HAVING SUM(MemWithdrawal) > 0

			INSERT INTO @tempData (MonthDate,AffId,GroupId,ProductId,ActivePlayer)
			SELECT MonthDate,AffId,0,0,COUNT(1) AS ActivePlayer
			FROM
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate,AffId,IBCCustId,SUM(Turnover) AS Turnover,SUM(Deposit) AS Deposit
				FROM dbo.MemberDaily WITH (NOLOCK)
				WHERE WinlostDate BETWEEN DATEADD(MONTH, -1, DATEADD(DAY, 1, @tempFromMonth)) AND @tempToMonth
				GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)),AffId,IBCCustId
			) AS dt
			WHERE Turnover > 0 OR Deposit > 0
			GROUP BY MonthDate,AffId
		END
		ELSE
		BEGIN
			WITH CTE_MonthDate AS
			(
				SELECT @tempFrom AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempTo
			)
			INSERT INTO @MonthDate (MonthDate, AffId)
			SELECT MonthDate, val AS AffId FROM CTE_MonthDate CROSS JOIN dbo.Aff_f_StringSplit(@AffIds, ',') f
			OPTION (MAXRECURSION 0)

			INSERT INTO @tempData
			(
				MonthDate,AffId,GroupId,ProductId,Deposit,Bonus,Turnover,Winloss,
				NetWinloss,QualifiedMember,CommissionRate,Commission
			)
			SELECT
				dt.MonthDate,dt.AffId,dt.GroupId,dt.ProductId,dt.Deposit,dt.Bonus,dt.Turnover,dt.Winloss,
				dt.NetWinloss,dt.QualifiedMember,dt.CommissionRate,dt.Commission
			FROM @MonthDate md
				CROSS APPLY (
					SELECT TOP (@n)
						MonthDate,AffId,GroupId,SportId AS ProductId,MemberDeposit AS Deposit,MemberBonus AS Bonus,MemberTurnover AS Turnover,MemberWinlost AS Winloss,
						(AffWinlost+MemberBonus) AS NetWinloss,QualifiedMember,Commission AS CommissionRate,AffWinlost*Commission AS Commission
					FROM dbo.AffCommission ac WITH (NOLOCK)
					WHERE ac.WinlostDate = md.MonthDate
						AND ac.AffId = md.AffId
						AND (ac.MemberDeposit > 0 OR ac.MemberTurnover > 0)
				) AS dt
			OPTION (OPTIMIZE FOR (@n=1))

			INSERT INTO @tempData (MonthDate,AffId,GroupId,ProductId,Withdrawal)
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate,AffId,0,0,SUM(MemWithdrawal) AS Withdrawal
			FROM dbo.AffDailySummary ad WITH (NOLOCK)
				INNER JOIN dbo.Aff_f_StringSplit(@AffIds, ',') f ON ad.AffId = f.val
			WHERE WinlostDate BETWEEN DATEADD(MONTH, -1, DATEADD(DAY, 1, @tempFromMonth)) AND @tempToMonth
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)),AffId
			HAVING SUM(MemWithdrawal) > 0
			OPTION (MAXRECURSION 0)

			INSERT INTO @tempData (MonthDate,AffId,GroupId,ProductId,ActivePlayer)
			SELECT MonthDate,AffId,0,0,COUNT(1) AS ActivePlayer
			FROM
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate,AffId,IBCCustId,SUM(Turnover) AS Turnover,SUM(Deposit) AS Deposit
				FROM dbo.MemberDaily md WITH (NOLOCK)
				WHERE WinlostDate BETWEEN DATEADD(MONTH, -1, DATEADD(DAY, 1, @tempFromMonth)) AND @tempToMonth
					AND ',' + CONVERT(VARCHAR(20), AffId) + ',' LIKE '%,' + @AffIds + ',%'
				GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)),AffId,IBCCustId
			) AS dt
			WHERE Turnover > 0 OR Deposit > 0
			GROUP BY MonthDate,AffId
			HAVING COUNT(1) > 0
			OPTION (MAXRECURSION 0)
		END

		-- By Product
		INSERT INTO #AffCommission
		(
			MonthDate,AffId,GroupId,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss,
			NetWinloss,ActivePlayer,QualifiedMember,QMTurnover,CommissionRate,Commission
		)
		SELECT
			MonthDate,AffId,GroupId,ProductId,0 AS Deposit,0 AS Withdrawal,0 AS Bonus,SUM(Turnover),SUM(Winloss),
			0 AS NetWinloss,0 AS ActivePlayer,0 AS QualifiedMember,0 AS QMTurnover,0 AS CommissionRate,0 AS Commission
		FROM @tempData
		WHERE ProductId > 0
		GROUP BY MonthDate,AffId,GroupId,ProductId

		-- Total
		INSERT INTO #AffCommission
		(
			MonthDate,AffId,GroupId,ProductId,Deposit,Bonus,Turnover,Winloss,
			NetWinloss,QualifiedMember,QMTurnover,CommissionRate,Commission
		)
		SELECT
			MonthDate,AffId,MAX(GroupId) AS GroupId,0 AS ProductId,SUM(ISNULL(Deposit, 0)),SUM(ISNULL(Bonus, 0)),SUM(ISNULL(Turnover, 0)),SUM(ISNULL(Winloss, 0)),
			SUM(ISNULL(NetWinloss, 0)),SUM(ISNULL(QualifiedMember, 0)),100 AS QMTurnover,SUM(ISNULL(CommissionRate, 0)),SUM(ISNULL(Commission, 0))
		FROM @tempData
		WHERE ProductId > 0
		GROUP BY
			MonthDate, AffId

		UPDATE ac
		SET ac.Withdrawal = ISNULL(t.Withdrawal, 0), ac.ActivePlayer = ISNULL(t.ActivePlayer, 0)
		FROM #AffCommission ac
			CROSS APPLY (
				SELECT SUM(ISNULL(td.Withdrawal, 0)) AS Withdrawal, SUM(ISNULL(td.ActivePlayer, 0)) AS ActivePlayer
				FROM @tempData td
				WHERE td.ProductId = 0 AND ac.MonthDate = td.MonthDate AND ac.AffId = td.AffId
			) AS t
	END

	-- Return data
	SELECT
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Turnover,
		Winloss,
		ISNULL(PlatFormFee, 0) AS PlatFormFee,
		ISNULL(OperationalFee, 0) AS OperationalFee,
		ISNULL(BankingFee, 0) AS BankingFee,
		NetWinloss,
		ActivePlayer,
		QualifiedMember,
		QMTurnOver,
		CommissionRate,
		Commission
	FROM #AffCommission ac
		CROSS APPLY (
			SELECT
				SUM(CASE WHEN ad.DeductionId = 10 THEN Amount ELSE 0 END) AS PlatFormFee,
				SUM(CASE WHEN ad.DeductionId = 11 THEN Amount ELSE 0 END) AS OperationalFee,
				SUM(CASE WHEN ad.DeductionId = 12 THEN Amount ELSE 0 END) AS BankingFee
			FROM dbo.rptAffDeduction ad WITH (NOLOCK)
			WHERE ac.MonthDate = ad.MonthDate AND ac.AffId = ad.AffId
		) AS f

	DROP TABLE #AffCommission
END
GO