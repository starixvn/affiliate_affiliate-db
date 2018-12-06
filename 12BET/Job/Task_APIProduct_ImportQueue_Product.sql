/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

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
		- 20181201@Percy: Integrate new products: 12Crystal - GPI, 12Quartz - iSoftbet [RedmineID: #104892]
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
			SUM(ISNULL(b.Amount, 0)) AS Turnover,
			SUM(ISNULL(b.win, 0) - ISNULL(b.Amount, 0)) AS Winloss
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
			SUM(CASE WHEN i.TYPE = 'BET' THEN ISNULL(i.Amount, 0) ELSE 0 END) AS Turnover,
			SUM(CASE WHEN i.TYPE = 'BET' THEN -ISNULL(i.Amount, 0) WHEN i.TYPE = 'WIN' THEN ISNULL(i.Amount, 0) ELSE 0 END) AS Winloss
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