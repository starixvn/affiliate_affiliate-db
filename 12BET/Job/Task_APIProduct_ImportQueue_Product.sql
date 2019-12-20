/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_Product]
	@ProductId		INT,
	@WinlostDate	SMALLDATETIME
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - API Products

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20181201@Percy: Integrate new products: 12Crystal - GPI, 12Quartz - iSoftbet, 12Diamond - OPUS [RedmineID: #104892]
		- 20190117@Percy: Divide amount by 100 for Betsoft [RedmineID: #107979]
		- 20190131@Percy: Divide amount by 100 for iSoftbet [RedmineID: #107979]
		- 20190322@Percy: Include more type of iSoftbet [RedmineID: #110638]
		- 20191206@Percy: Integrate new products: 12Topaz, LB Keno, GPI lottery, VR Lottery [RedmineID: #117197]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempData
	(
		AffId		INT,
		IBCCustId	INT,
		Currency	INT,
		Turnover	MONEY,
		Winloss		MONEY
	)

	-- Ebet
	IF @ProductId = 10
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(b.Bet, 0)) AS Turnover,
			SUM(ISNULL(b.Payout, 0) - ISNULL(b.Bet, 0)) AS Winloss
		FROM dbo.bettrans_Ebet b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
		WHERE b.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- Betsoft
	ELSE IF @ProductId = 11
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(b.Amount, 0) / 100) AS Turnover,
			SUM(ISNULL(b.Win, 0) / 100 - ISNULL(b.Amount, 0) / 100) AS Winloss
		FROM dbo.bettrans_Betsoft b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
		WHERE b.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- Crystal
	ELSE IF @ProductId = 12
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(c.bet, 0)) AS Turnover,
			SUM(ISNULL(c.changes, 0)) AS Winloss
		FROM dbo.bettrans_Crystal c WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON c.IBCCustId = mi.IBCCustId
		WHERE c.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- iSoftbet
	ELSE IF @ProductId = 13
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(CASE WHEN i.TYPE LIKE '%BET%' THEN ISNULL(i.Amount, 0)/100 ELSE 0 END) AS Turnover,
			SUM(CASE WHEN i.TYPE LIKE '%BET%' THEN -ISNULL(i.Amount, 0)/100 WHEN i.TYPE LIKE '%WIN%' THEN ISNULL(i.Amount, 0)/100 ELSE 0 END) AS Winloss
		FROM dbo.bettrans_iSoftbet i WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON i.IBCCustId = mi.IBCCustId
		WHERE i.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- OPUS
	ELSE IF @ProductId = 14
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(o.bet, 0)) AS Turnover,
			SUM(ISNULL(o.win, 0) - ISNULL(o.bet, 0)) AS Winloss
		FROM dbo.bettrans_OPUS o WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON o.IBCCustId = mi.IBCCustId
		WHERE o.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- GPI Lottery
	ELSE IF @ProductId = 20
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(g.betAmount, 0)) AS Turnover,
			SUM(ISNULL(g.winAmount, 0) - ISNULL(g.betAmount, 0)) AS Winloss
		FROM dbo.bettrans_GPILottery g WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON g.IBCCustId = mi.IBCCustId
		WHERE g.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND g.status = 'Settled'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- VR Lottery
	ELSE IF @ProductId = 21
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(v.BetAmount, 0)) AS Turnover,
			SUM(ISNULL(v.PlayerWinLoss, 0)) AS Winloss
		FROM dbo.bettrans_VRLottery v WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON v.IBCCustId = mi.IBCCustId
		WHERE v.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND v.status = 'Settled'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- LB Keno
	ELSE IF @ProductId = 22
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(l.bet_money, 0)) AS Turnover,
			SUM(ISNULL(l.bet_winning, 0)) AS Winloss
		FROM dbo.bettrans_LBKeno l WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON l.IBCCustId = mi.IBCCustId
		WHERE l.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND l.bet_status = 'Settled'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- 12 Topaz
	ELSE IF @ProductId = 23
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(CASE WHEN t.tranType = 'GAME_BET' THEN ISNULL(t.amount, 0) ELSE 0 END) AS Turnover,
			SUM(CASE WHEN t.tranType = 'GAME_WIN' THEN ISNULL(t.amount, 0) ELSE 0 END) AS Winloss
		FROM dbo.bettrans_Topaz t WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON t.IBCCustId = mi.IBCCustId
		WHERE t.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END

	MERGE dbo.rptMemberDaily AS TARGET
	USING
		(
			SELECT AffId,IBCCustId,Turnover,Winloss,Currency,e.ActualRate AS ExRate,e.ActualRate2 AS AffExRate
			FROM #tempData d
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(d.Currency, @WinlostDate) e
		) AS SOURCE
		ON		TARGET.WinlostDate	= @WinlostDate
			AND TARGET.ProductId	= @ProductId
			AND TARGET.AffId		= SOURCE.AffId
			AND TARGET.IBCCustId	= SOURCE.IBCCustId
	WHEN MATCHED THEN UPDATE
		SET TARGET.Deposit			= 0,
			TARGET.Withdrawal		= 0,
			TARGET.Bonus			= 0,
			TARGET.Adjustment		= 0,
			TARGET.Turnover			= SOURCE.Turnover,
			TARGET.Winloss			= SOURCE.Winloss
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
		(
			WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate
		)
		VALUES
		(
			@WinlostDate,AffId,IBCCustId,@ProductId,0,0,0,0,Turnover,Winloss,Currency,ExRate,AffExRate
		)
	WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @WinlostDate AND TARGET.ProductId = @ProductId THEN DELETE;

	DROP TABLE #tempData
END
GO