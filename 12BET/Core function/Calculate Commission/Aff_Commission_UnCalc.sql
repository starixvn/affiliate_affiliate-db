/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Commission_UnCalc]
	@AffIds			VARCHAR(MAX) = 'all',
	@FromMonthDate	SMALLDATETIME,
	@ToMonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core SP - Calculate commission for months which are not calculated yet

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfFromMonthDate SMALLDATETIME, @EndOfToMonthDate SMALLDATETIME

	SELECT  @BeginOfFromMonthDate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromMonthDate), 0) -- First day of @FromMonthDate
	SELECT  @EndOfToMonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToMonthDate) + 1, 0)) -- Last day of @ToMonthDate

	IF @EndOfToMonthDate > CONVERT(DATE, GETDATE())
		SELECT @EndOfToMonthDate = CONVERT(DATE, GETDATE())

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	CREATE TABLE #Data
	(
		MonthDate		SMALLDATETIME,
		AffId			INT,
		IBCCustId		INT,
		ProductId		INT,
		Deposit			MONEY,
		Withdrawal		MONEY,
		Bonus			MONEY,
		Turnover		MONEY,
		Winloss			MONEY
	)

	CREATE TABLE #Commission
	(
		MonthDate		SMALLDATETIME,
		AffId			INT,
		GroupId			INT,
		ProductId		INT,
		Deposit			MONEY DEFAULT (0),
		Withdrawal		MONEY DEFAULT (0),
		Bonus			MONEY DEFAULT (0),
		Turnover		MONEY DEFAULT (0),
		Winloss			MONEY DEFAULT (0),
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

	CREATE CLUSTERED INDEX CIX_MonthDate ON #Data (MonthDate, AffId, IBCCustId, ProductId)
	CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commission (MonthDate, AffId, GroupId, ProductId)

	-- get data from rptMemberDaily and Bettrans
	BEGIN
		DECLARE @tmpDate SMALLDATETIME

		IF @AffIds = 'all'
		BEGIN
			-- rptMemberDaily
			INSERT INTO #Data
			(
				MonthDate,
				AffId,
				IBCCustId,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Turnover,
				Winloss
			)
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate, -- last day of month
				md.AffId,
				md.IBCCustId,
				md.ProductId,
				SUM(ISNULL(md.Deposit, 0)	* ISNULL(md.AffExRate, 1)) AS Deposit,
				SUM(ISNULL(md.Withdrawal, 0)* ISNULL(md.AffExRate, 1)) AS Withdrawal,
				SUM(ISNULL(md.Bonus, 0)		* ISNULL(md.AffExRate, 1)) AS Bonus,
				SUM(ISNULL(md.Turnover, 0)	* ISNULL(md.AffExRate, 1)) AS Turnover,
				SUM(ISNULL(md.Winloss, 0)	* ISNULL(md.AffExRate, 1)) AS Winloss
			FROM dbo.rptMemberDaily md WITH (NOLOCK)
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 0, md.WinlostDate, @MoveBetsDay) f
			WHERE md.WinlostDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
			GROUP BY
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
				md.AffId,
				md.IBCCustId,
				md.ProductId

			-- Bettrans
			IF @EndOfToMonthDate > @MoveBetsDay
			BEGIN
				SELECT @tmpDate = CASE WHEN @BeginOfFromMonthDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @BeginOfFromMonthDate END

				MERGE #Data AS TARGET
				USING
				(
					SELECT
						DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate, -- last day of month
						mi.AffId,
						md.IBCCustId,
						md.ProductId,
						SUM(ISNULL(md.Deposit, 0)	* ISNULL(e.ActualRate2, 1)) AS Deposit,
						SUM(ISNULL(md.Withdrawal, 0)* ISNULL(e.ActualRate2, 1)) AS Withdrawal,
						SUM(ISNULL(md.Bonus, 0)		* ISNULL(e.ActualRate2, 1)) AS Bonus,
						SUM(ISNULL(md.Turnover, 0)	* ISNULL(e.ActualRate2, 1)) AS Turnover,
						SUM(ISNULL(md.Winloss, 0)	* ISNULL(e.ActualRate2, 1)) AS Winloss
					FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,ProductId,Currency,Deposit,Withdrawal,Bonus,Turnover,Winloss
											FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
						CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
						CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
						INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId
					WHERE NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
								AND mr.IBCCustId = mi.IBCCustId
						)
						AND md.WinlostDate BETWEEN @tmpDate AND @EndOfToMonthDate
					GROUP BY
						DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
						mi.AffId,
						md.IBCCustId,
						md.ProductId
				) AS SOURCE
				(
					MonthDate,AffId,IBCCustId,ProductId,
					Deposit,Withdrawal,Bonus,Turnover,Winloss
				)
					ON		TARGET.MonthDate = SOURCE.MonthDate
						AND TARGET.AffId	 = SOURCE.AffId
						AND TARGET.IBCCustId = SOURCE.IBCCustId
						AND TARGET.ProductId = SOURCE.ProductId
				WHEN MATCHED THEN
					UPDATE SET
						TARGET.Deposit		= ISNULL(TARGET.Deposit, 0)	+ ISNULL(SOURCE.Deposit, 0),
						TARGET.Withdrawal	= ISNULL(TARGET.Withdrawal, 0) + ISNULL(SOURCE.Withdrawal, 0),
						TARGET.Bonus		= ISNULL(TARGET.Bonus, 0)		+ ISNULL(SOURCE.Bonus, 0),
						TARGET.Turnover		= ISNULL(TARGET.Turnover, 0)	+ ISNULL(SOURCE.Turnover, 0),
						TARGET.Winloss		= ISNULL(TARGET.Winloss, 0)	+ ISNULL(SOURCE.Winloss, 0)
				WHEN NOT MATCHED BY TARGET THEN
					INSERT
					(
						MonthDate,AffId,IBCCustId,ProductId,
						Deposit,Withdrawal,Bonus,Turnover,Winloss
					)
					VALUES
					(
						SOURCE.MonthDate,SOURCE.AffId,SOURCE.IBCCustId,SOURCE.ProductId,
						SOURCE.Deposit,SOURCE.Withdrawal,SOURCE.Bonus,SOURCE.Turnover,SOURCE.Winloss
					)
				OPTION (MAXRECURSION 0);
			END
		END
		ELSE
		BEGIN
			-- rptMemberDaily
			INSERT INTO #Data
			(
				MonthDate,
				AffId,
				IBCCustId,
				ProductId,
				Deposit,
				Withdrawal,
				Bonus,
				Turnover,
				Winloss
			)
			SELECT
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate, -- last day of month
				md.AffId,
				md.IBCCustId,
				md.ProductId,
				SUM(ISNULL(md.Deposit, 0)	* ISNULL(md.AffExRate, 1)) AS Deposit,
				SUM(ISNULL(md.Withdrawal, 0)* ISNULL(md.AffExRate, 1)) AS Withdrawal,
				SUM(ISNULL(md.Bonus, 0)		* ISNULL(md.AffExRate, 1)) AS Bonus,
				SUM(ISNULL(md.Turnover, 0)	* ISNULL(md.AffExRate, 1)) AS Turnover,
				SUM(ISNULL(md.Winloss, 0)	* ISNULL(md.AffExRate, 1)) AS Winloss
			FROM dbo.rptMemberDaily md WITH (NOLOCK)
				INNER JOIN dbo.Aff_f_StringSplit(@AffIds, ',') s ON md.AffId = s.val
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 0, md.WinlostDate, @MoveBetsDay) f
			WHERE md.WinlostDate BETWEEN @BeginOfFromMonthDate AND @EndOfToMonthDate
			GROUP BY
				DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
				md.AffId,
				md.IBCCustId,
				md.ProductId
			OPTION (MAXRECURSION 0)

			-- Bettrans
			IF @EndOfToMonthDate > @MoveBetsDay
			BEGIN
				SELECT @tmpDate = CASE WHEN @BeginOfFromMonthDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @BeginOfFromMonthDate END

				MERGE #Data AS TARGET
				USING
				(
					SELECT
						DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)) AS MonthDate, -- last day of month
						s.val AS AffId,
						md.IBCCustId,
						md.ProductId,
						SUM(ISNULL(md.Deposit, 0)	* ISNULL(e.ActualRate2, 1)) AS Deposit,
						SUM(ISNULL(md.Withdrawal, 0)* ISNULL(e.ActualRate2, 1)) AS Withdrawal,
						SUM(ISNULL(md.Bonus, 0)		* ISNULL(e.ActualRate2, 1)) AS Bonus,
						SUM(ISNULL(md.Turnover, 0)	* ISNULL(e.ActualRate2, 1)) AS Turnover,
						SUM(ISNULL(md.Winloss, 0)	* ISNULL(e.ActualRate2, 1)) AS Winloss
					FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,ProductId,Currency,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss
											FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
						CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
						CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
						INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId
						INNER JOIN dbo.Aff_f_StringSplit(@AffIds, ',') s ON mi.AffId = s.val
					WHERE NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
								AND mr.IBCCustId = mi.IBCCustId
						)
						AND md.WinlostDate BETWEEN @tmpDate AND @EndOfToMonthDate
					GROUP BY
						DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0)),
						s.val,
						md.IBCCustId,
						md.ProductId
				) AS SOURCE
				(
					MonthDate,AffId,IBCCustId,ProductId,
					Deposit,Withdrawal,Bonus,Turnover,Winloss
				)
					ON		TARGET.MonthDate = SOURCE.MonthDate
						AND TARGET.AffId	 = SOURCE.AffId
						AND TARGET.IBCCustId = SOURCE.IBCCustId
						AND TARGET.ProductId = SOURCE.ProductId
				WHEN MATCHED THEN
					UPDATE SET
						TARGET.Deposit		= TARGET.Deposit	+ SOURCE.Deposit,
						TARGET.Withdrawal	= TARGET.Withdrawal + SOURCE.Withdrawal,
						TARGET.Bonus		= TARGET.Bonus		+ SOURCE.Bonus,
						TARGET.Turnover		= TARGET.Turnover	+ SOURCE.Turnover,
						TARGET.Winloss		= TARGET.Winloss	+ SOURCE.Winloss
				WHEN NOT MATCHED BY TARGET THEN
					INSERT
					(
						MonthDate,AffId,IBCCustId,ProductId,
						Deposit,Withdrawal,Bonus,Turnover,Winloss
					)
					VALUES
					(
						SOURCE.MonthDate,SOURCE.AffId,SOURCE.IBCCustId,SOURCE.ProductId,
						SOURCE.Deposit,SOURCE.Withdrawal,SOURCE.Bonus,SOURCE.Turnover,SOURCE.Winloss
					)
				OPTION (MAXRECURSION 0);
			END
		END
	END

	-- Setting
	BEGIN
		DECLARE @Setting TABLE
		(
			MonthDate		SMALLDATETIME,
			AffId			INT,
			GroupId			INT,
			ProductId		INT,
			PlatFormFee		DECIMAL(9,8) DEFAULT (0),
			OperationalFee	DECIMAL(9,8) DEFAULT (0),
			BankingFee		DECIMAL(9,8) DEFAULT (0)
		)
	
		;WITH CTE_MonthDate AS
		(
			SELECT MonthDate, AffId
			FROM #Data
			GROUP BY MonthDate, AffId
		)
		INSERT INTO @Setting
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			PlatFormFee,
			OperationalFee,
			BankingFee
		)
		SELECT
			md.MonthDate,
			md.AffId,
			agh.GroupId,
			ds.ProductId,
			ds.PlatFormFee,
			ds.OperationalFee,
			ds.BankingFee
		FROM CTE_MonthDate md
			INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON md.MonthDate = agh.MonthDate AND md.AffId = agh.AffId
			CROSS APPLY (
				SELECT
					dsh.ProductId,
					SUM(CASE WHEN dsh.DeductionId = 10 THEN dsh.DeductedPercentage ELSE 0 END) AS PlatFormFee,
					SUM(CASE WHEN dsh.DeductionId = 11 THEN dsh.DeductedPercentage ELSE 0 END) AS OperationalFee,
					SUM(CASE WHEN dsh.DeductionId = 12 THEN dsh.DeductedPercentage ELSE 0 END) AS BankingFee
				FROM dbo.DeductionSettingHistory dsh WITH (NOLOCK)
				WHERE agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
				GROUP BY
					dsh.ProductId
			) AS ds
		OPTION (MAXRECURSION 0)
	END

	-- Calculate commission
	BEGIN
		-- Group by Product
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			ProductId,
			Turnover,
			Winloss
		)
		SELECT
			MonthDate,
			AffId,
			ProductId,
			SUM(Turnover) AS Turnover,
			SUM(Winloss) AS Winloss
		FROM #Data
		WHERE ProductId > 0
		GROUP BY
			MonthDate,
			AffId,
			ProductId

		-- Total
		;WITH CTE_SumMember AS
		(
			SELECT
				MonthDate,
				AffId,
				IBCCustId,
				SUM(Turnover) AS Turnover,
				SUM(Deposit) AS Deposit
			FROM #Data
			GROUP BY
				MonthDate,
				AffId,
				IBCCustId
		)
		INSERT INTO #Commission
		(
			MonthDate,
			AffId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnover
		)
		SELECT
			MonthDate,
			AffId,
			0 AS ProductId,
			SUM(Deposit)			AS Deposit,
			SUM(Withdrawal)			AS Withdrawal,
			SUM(Bonus)				AS Bonus,
			SUM(Turnover)			AS Turnover,
			SUM(Winloss)			AS Winloss,
			SUM(ActivePlayer)		AS ActivePlayer,
			SUM(QualifiedMember)	AS QualifiedMember,
			SUM(QMTurnover)			AS QMTurnover
		FROM
		(
			SELECT
				dt.MonthDate,
				dt.AffId,
				0 AS Deposit,
				0 AS Withdrawal,
				0 AS Bonus,
				0 AS Turnover,
				0 AS Winloss,
				SUM(CASE WHEN dt.Turnover > 0 OR dt.Deposit > 0 THEN 1 ELSE 0 END) AS ActivePlayer,
				SUM(CASE WHEN dt.Turnover >= ISNULL(cgh.QMTurnOver, 0) THEN 1 ELSE 0 END) AS QualifiedMember,
				ISNULL(cgh.QMTurnover, 0) AS QMTurnover
			FROM CTE_SumMember dt
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON dt.AffId = agh.AffId AND dt.MonthDate = agh.MonthDate
				INNER JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) ON agh.GroupId = cgh.GroupId AND agh.MonthDate = cgh.MonthDate
			GROUP BY
				dt.MonthDate,
				dt.AffId,
				ISNULL(cgh.QMTurnover, 0)

			UNION ALL
			SELECT
				MonthDate,
				AffId,
				SUM(Deposit) AS Deposit,
				SUM(Withdrawal) AS Withdrawal,
				SUM(Bonus) AS Bonus,
				SUM(Turnover) AS Turnover,
				SUM(Winloss) AS Winloss,
				0 AS ActivePlayer,
				0 AS QualifiedMember,
				0 AS QMTurnover
			FROM #Data
			GROUP BY
				MonthDate,
				AffId
		) AS A
		GROUP BY
			MonthDate,
			AffId

		-- Calculate fees
		UPDATE c
		SET c.GroupId			= s.GroupId,
			c.PlatFormFee		= ABS(c.Winloss) * s.PlatFormFee,
			c.OperationalFee	= ABS(c.Winloss) * s.OperationalFee,
			c.BankingFee		= (c.Deposit + c.Withdrawal) * s.BankingFee
		FROM #Commission c
			INNER JOIN @Setting s ON c.AffId = s.AffId AND c.MonthDate = s.MonthDate AND c.ProductId = s.ProductId

		UPDATE c
		SET c.PlatFormFee	= pf.PlatFormFee
		FROM #Commission c
			CROSS APPLY (
				SELECT SUM(c1.PlatFormFee) AS PlatFormFee
				FROM #Commission c1
				WHERE c.MonthDate = c1.MonthDate AND c.AffId = c1.AffId
					AND c1.ProductId > 0
			) AS pf
		WHERE c.ProductId = 0

		-- Net Winloss
		UPDATE #Commission
		SET NetWinloss = -Winloss - (PlatFormFee + OperationalFee + BankingFee)
		FROM #Commission
		WHERE ProductId = 0
	
		-- Commission
		UPDATE c
		SET c.CommissionRate	= ISNULL(s.Commission, 0),
			c.Commission		= ISNULL(s.Commission, 0) * (c.NetWinloss - c.Bonus)
		FROM #Commission c
			CROSS APPLY (
				SELECT gsh.TierId
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId
					AND FLOOR(ABS(c.NetWinloss)) BETWEEN gsh.MinAmount AND gsh.MaxAmount
			) AS t
			CROSS APPLY (
				SELECT MIN(gsh.Commission) AS Commission
				FROM dbo.TierSettingHistory gsh WITH (NOLOCK)
				WHERE c.MonthDate = gsh.MonthDate AND c.GroupId = gsh.GroupId
					AND c.QualifiedMember BETWEEN gsh.MinQM AND gsh.MaxQM
					AND gsh.TierId <= t.TierId
			) AS s
		WHERE c.ProductId = 0
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

	DROP TABLE #Data
	DROP TABLE #Commission
END
GO