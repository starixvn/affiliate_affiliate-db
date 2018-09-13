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

	-- Get old data
	DECLARE @CutOffDate SMALLDATETIME, @IsOldData BIT = 0
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @EndMonthOfFrom SMALLDATETIME, @EndMonthOfTo SMALLDATETIME

	SELECT  @EndMonthOfFrom = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate) + 1, 0))
	SELECT  @EndMonthOfTo	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0))

	IF @CutOffDate >= @EndMonthOfFrom
		SELECT @IsOldData = 1

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	;WITH CTE_MonthDate AS
	(
		SELECT @EndMonthOfFrom AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @EndMonthOfTo
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT MonthDate FROM CTE_MonthDate
	OPTION (MAXRECURSION 0)

	CREATE TABLE #Commission
	(
		MonthDate		SMALLDATETIME,
		AffId			INT,
		GroupId			INT,
		GroupProductId	TINYINT,
		ProductId		INT,
		Deposit			MONEY,
		Withdrawal		MONEY,
		Bonus			MONEY,
		Turnover		MONEY,
		Winloss			MONEY,
		-- Fees
		PlatFormFee		MONEY DEFAULT (0),
		OperationalFee	MONEY DEFAULT (0),
		BankingFee		MONEY DEFAULT (0),
		-- Calculation
		NetWinloss		MONEY DEFAULT (0),
		ActivePlayer	INT DEFAULT (0),
		QualifiedMember INT DEFAULT (0),
		QMTurnover		MONEY DEFAULT (0),
		CommissionRate	DECIMAL(9,8) DEFAULT (0),
		Commission		MONEY DEFAULT (0)
	)

	CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)

	-- Setting
	DECLARE @Setting TABLE
	(
		MonthDate		SMALLDATETIME,
		AffId			INT,
		GroupId			INT,
		GroupProductId	TINYINT,
		ProductId		INT,
		PlatFormFee		DECIMAL(9,8) DEFAULT (0),
		OperationalFee	DECIMAL(9,8) DEFAULT (0),
		BankingFee		DECIMAL(9,8) DEFAULT (0)
	)
	
	IF @AffIds = 'all'
	BEGIN
		INSERT INTO @Setting
		(
			MonthDate,
			GroupId,
			ProductId,
			GroupProductId,
			PlatFormFee,
			OperationalFee,
			BankingFee
		)
		SELECT
			dsh.MonthDate,
			dsh.GroupId,
			dsh.ProductId,
			dsh.GroupProductId,
			SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
			SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
			SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedPercentage ELSE 0 END) AS BankingFee
		FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK)
			INNER JOIN @MonthDate md ON dsh.MonthDate = md.MonthDate
		GROUP BY
			dsh.MonthDate,
			dsh.GroupId,
			dsh.ProductId,
			dsh.GroupProductId
	END
	ELSE
	BEGIN
		INSERT INTO @Setting
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			GroupProductId,
			PlatFormFee,
			OperationalFee,
			BankingFee
		)
		SELECT
			dsh.MonthDate,
			agh.AffId,
			dsh.GroupId,
			dsh.ProductId,
			dsh.GroupProductId,
			SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
			SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
			SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedPercentage ELSE 0 END) AS BankingFee
		FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK)
			INNER JOIN @MonthDate md ON dsh.MonthDate = md.MonthDate
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON dsh.MonthDate = agh.MonthDate AND dsh.GroupId = agh.GroupId
			INNER JOIN dbo.Aff_f_StringSplit(@AffIds, ',') a ON a.val = agh.AffId
		GROUP BY
			dsh.MonthDate,
			agh.AffId,
			dsh.GroupId,
			dsh.ProductId,
			dsh.GroupProductId
		OPTION (MAXRECURSION 0)
	END

	IF @AffIds = 'all'
	BEGIN
		-- Per Product
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			GroupProductId,
			Turnover,
			Winloss,
			PlatFormFee
		)
		SELECT
			ac.MonthDate,
			ac.AffId,
			ac.GroupId,
			ac.ProductId,
			s.GroupProductId,
			ac.Turnover,
			ac.Winloss,
			ac.Winloss * ISNULL(s.PlatFormFee, 0) AS PlatFormFee
		FROM dbo.rptAffCommission ac WITH (NOLOCK)
			INNER JOIN @Setting s ON ac.GroupId = s.GroupId AND ac.MonthDate = s.MonthDate AND ac.ProductId = s.ProductId
		WHERE ac.ProductId > 0

		-- Total
		INSERT INTO #Commission
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
			OperationalFee,
			BankingFee,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnover,
			CommissionRate,
			Commission
		)
		SELECT
			ac.MonthDate,
			ac.AffId,
			ac.GroupId,
			ac.ProductId,
			ac.Deposit,
			ac.Withdrawal,
			ac.Bonus,
			ac.Turnover,
			ac.Winloss,
			ABS(ac.Winloss) * s.OperationalFee AS OperationalFee,
			(ac.Deposit + ac.Withdrawal) * s.BankingFee AS BankingFee,
			ac.NetWinloss,
			ac.ActivePlayer,
			ac.QualifiedMember,
			ac.QMTurnover,
			ac.CommissionRate,
			ac.NetWinloss * ac.CommissionRate AS Commission
		FROM dbo.rptAffCommission ac WITH (NOLOCK)
			INNER JOIN @Setting s ON ac.GroupId = s.GroupId AND ac.MonthDate = s.MonthDate AND ac.ProductId = s.ProductId
		WHERE ac.ProductId = 0

		;WITH CTE_PlatFormFee AS
		(
			SELECT
				MonthDate,
				AffId,
				SUM(ABS(PlatFormFee)) AS PlatFormFee
			FROM
			(
				SELECT
					MonthDate,
					AffId,
					GroupProductId,
					SUM(PlatFormFee) AS PlatFormFee
				FROM #Commission
				WHERE ProductId > 0
				GROUP BY
					MonthDate,
					AffId,
					GroupProductId
			) AS pf
			GROUP BY
				MonthDate,
				AffId
		)
		UPDATE c
		SET c.PlatFormFee	= pf.PlatFormFee
		FROM #Commission c
			INNER JOIN CTE_PlatFormFee pf ON c.MonthDate = pf.MonthDate AND c.AffId = pf.AffId
		WHERE c.ProductId = 0

		-- Get old data
		IF @IsOldData = 1
		BEGIN
			INSERT INTO #Commission
			(
				MonthDate,
				AffId,
				GroupId,
				ProductId,
				Turnover,
				Winloss,
				PlatFormFee
			)
			SELECT
				ac.WinlostDate,
				ac.AffId,
				ac.GroupId,
				ac.SportID AS ProductId,
				ac.MemberTurnover AS Turnover,
				ac.MemberWinlost AS Winloss,
				0 AS PlatFormFee
			FROM dbo.AffCommission ac WITH (NOLOCK)
				INNER JOIN @Setting s ON ac.GroupId = s.GroupId AND ac.WinlostDate = s.MonthDate AND ac.SportID = s.ProductId
			WHERE ac.WinlostDate <= @CutOffDate

			INSERT INTO #Commission
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
				OperationalFee,
				BankingFee,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnover,
				CommissionRate,
				Commission
			)
			SELECT
				ac.WinlostDate,
				ac.AffId,
				ac.GroupId,
				0 AS ProductId,
				SUM(ISNULL(ac.MemberDeposit, 0))	AS Deposit,
				0 AS Withdrawal,
				SUM(ISNULL(ac.MemberBonus, 0))		AS Bonus,
				SUM(ISNULL(ac.MemberTurnover, 0))	AS Turnover,
				SUM(ISNULL(ac.MemberWinlost, 0))	AS Winloss,
				0 AS OperationalFee,
				0 AS BankingFee,
				SUM(ISNULL(ac.AffWinlost, 0))		AS NetWinloss,
				0 AS ActivePlayer,
				SUM(ISNULL(ac.QualifiedMember, 0))	AS QualifiedMember,
				SUM(ISNULL(ac.MemberWinlost, 0))	AS QMTurnover,
				SUM(ISNULL(ac.Commission, 0))		AS CommissionRate,
				SUM(ISNULL(ac.AffWinlost * ac.Commission, 0))	AS Commission
			FROM dbo.AffCommission ac WITH (NOLOCK)
				INNER JOIN @Setting s ON ac.GroupId = s.GroupId AND ac.WinlostDate = s.MonthDate AND ac.SportID = s.ProductId
			WHERE ac.WinlostDate <= @CutOffDate
			GROUP BY
				ac.WinlostDate,
				ac.AffId,
				ac.GroupId

			-- get Active Players and Withdrawal
			INSERT INTO #Commission
			(
				MonthDate,
				AffId,
				ProductId,
				Withdrawal
			)
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate,
				AffId,
				Sporttype AS ProductId,
				SUM(Turnover) AS Turnover
			FROM dbo.MemberDaily WITH (NOLOCK)
			WHERE WinlostDate BETWEEN @EndMonthOfFrom AND @CutOffDate
			GROUP BY
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)),
				AffId,
				Sporttype

			INSERT INTO #Commission
			(
				MonthDate,
				AffId,
				ProductId,
				Withdrawal
			)
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, ad.WinlostDate) + 1, 0)) AS MonthDate,
				ad.AffId,
				0 AS ProductId,
				SUM(ISNULL(ad.MemWithdrawal, 0))
			FROM dbo.AffDailySummary ad WITH (NOLOCK)
				INNER JOIN @Setting s ON ad.WinlostDate = s.MonthDate AND ad.SportID = s.ProductId
			WHERE ad.WinlostDate <= @CutOffDate
			GROUP BY
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, ad.WinlostDate) + 1, 0)),
				ad.AffId
		END
	END
	ELSE
	BEGIN
		-- By Product
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			Turnover,
			Winloss,
			PlatFormFee
		)
		SELECT
			ac.MonthDate,
			ac.AffId,
			ac.GroupId,
			ac.ProductId,
			ac.Turnover,
			ac.Winloss,
			ABS(ac.Winloss) * ISNULL(s.PlatFormFee, 0) AS PlatFormFee
		FROM dbo.rptAffCommission ac WITH (NOLOCK)
			INNER JOIN @Setting s ON ac.MonthDate = s.MonthDate AND ac.AffId = s.AffId AND ac.GroupId = s.GroupId AND ac.ProductId = s.ProductId
		WHERE ac.ProductId > 0

		-- Total
		INSERT INTO #Commission
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
			OperationalFee,
			BankingFee,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnover,
			CommissionRate,
			Commission
		)
		SELECT
			ac.MonthDate,
			ac.AffId,
			ac.GroupId,
			ac.ProductId,
			ac.Deposit,
			ac.Withdrawal,
			ac.Bonus,
			ac.Turnover,
			ac.Winloss,
			ABS(ac.Winloss) * s.OperationalFee AS OperationalFee,
			(ac.Deposit + ac.Withdrawal) * s.BankingFee AS BankingFee,
			ac.NetWinloss,
			ac.ActivePlayer,
			ac.QualifiedMember,
			ac.QMTurnover,
			ac.CommissionRate,
			ac.NetWinloss * ac.CommissionRate AS Commission
		FROM dbo.rptAffCommission ac WITH (NOLOCK)
			INNER JOIN @Setting s ON ac.MonthDate = s.MonthDate AND ac.AffId = s.AffId AND ac.GroupId = s.GroupId AND ac.ProductId = s.ProductId
		WHERE ac.ProductId = 0
	END

	UPDATE c
	SET c.PlatFormFee = c1.PlatFormFee
	FROM #Commission c
		INNER JOIN (
			SELECT
				MonthDate,
				GroupId,
				AffId,
				SUM(PlatFormFee) AS PlatFormFee
			FROM #Commission
			WHERE ProductId > 0
			GROUP BY
				MonthDate,
				GroupId,
				AffId
		) AS c1 ON c.MonthDate = c1.MonthDate AND c.GroupId = c1.GroupId AND c.AffId = c1.AffId
	WHERE c.ProductId = 0
	
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
		PlatFormFee,
		OperationalFee,
		BankingFee,
		NetWinloss,
		ActivePlayer,
		QualifiedMember,
		QMTurnOver,
		CommissionRate,
		Commission
	FROM #Commission

	DROP TABLE #Commission
END
GO