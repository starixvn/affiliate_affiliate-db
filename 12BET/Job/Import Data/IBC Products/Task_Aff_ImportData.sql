/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Import data of IBC's Products

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190108@Percy: Get Product List from bettrans (IsIBC = 1) [RedmineID: #107623]
		- 20190116@Percy: Add transfer: ProductId = -1 [RedmineID: #107623]
		- 20180117@Percy: Check product by releasedDate [RedmineID: #106503]
		- 20191127@Percy: Enhance performance [RedmineID: #118992]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)

	IF @WinlostDate IS NULL OR @WinlostDate <= @MoveBetsDay
		RETURN

	-- Get data
	BEGIN
		CREATE TABLE #tmpBettrans
		(
			winlostdate	SMALLDATETIME
			,custid		INT
			,ProductId	INT
			,Deposit	MONEY
			,Withdrawal	MONEY
			,Bonus		MONEY
			,Adjustment	MONEY
			,Turnover	MONEY
			,Winloss	MONEY
		)
			
		SELECT DISTINCT p.ProductId, s.bettype -- bet types of bet tickets
		INTO #_bettype
		FROM dbo.Products p WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Products ps WITH (NOLOCK) ON p.ProductPrefix = ps.ProductPrefix
			INNER JOIN bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK) ON ps.ProductID = s.ProductID
		WHERE p.IsIBC = 1
			AND p.Enabled = 1

		UNION ALL -- bet types of transfer tickets
		SELECT bt.ProductId, bt.Bettype
		FROM (
			VALUES
				-- -1: Deposit
				(-1, 22001),
				-- -2: Withdrawal
				(-2, 22002), (-2, 22003),
				-- -3: Bonus
				(-3, 22004), (-3, 22200),
				-- -4: Adjustment
				(-4, 21001), (-4, 21002), (-4, 21003), (-4, 21004), (-4, 21005),
				(-4, 22005), (-4, 22201)
		) AS bt (ProductId, Bettype)
			
		SELECT DISTINCT recommend
		INTO #_recommend
		FROM dbo.MemberInfo WITH (NOLOCK)
			
		INSERT INTO #tmpBettrans (custid, winlostdate, ProductId, Deposit, Withdrawal, Bonus, Adjustment, Turnover, Winloss)
		SELECT b.custid, b.winlostdate, CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END AS ProductId
			,SUM(CASE WHEN bt.ProductId = -1 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Deposit
			,SUM(CASE WHEN bt.ProductId = -2 THEN -(b.winlost-b.actual_stake)	ELSE 0 END) AS Withdrawal
			,SUM(CASE WHEN bt.ProductId = -3 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Bonus
			,SUM(CASE WHEN bt.ProductId = -4 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Adjustment
			,SUM(CASE WHEN bt.ProductId > 0 AND b.bettype <> 911 THEN b.stake	ELSE 0 END) AS Turnover
			,SUM(CASE WHEN bt.ProductId > 0 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS Winloss
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #_recommend r ON b.recommend = r.recommend
			INNER JOIN #_bettype bt ON b.bettype = bt.bettype
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 103)
		GROUP BY b.custid, b.winlostdate, CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END

		CREATE TABLE #rptMemberDaily
		(
			IBCCustId		INT
			,Currency		INT
			,AffId			INT
			,ProductId		INT
			,Deposit		MONEY
			,Withdrawal		MONEY
			,Bonus			MONEY
			,Adjustment		MONEY
			,Turnover		MONEY
			,Winloss		MONEY
			,AffExRate		FLOAT
			,ExRate			FLOAT
		)
		INSERT INTO #rptMemberDaily
		(
			IBCCustId
			,Currency
			,AffId
			,ProductId
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,Turnover
			,Winloss
			,AffExRate
			,ExRate
		)
		SELECT
			mi.IBCCustId
			,mi.Currency
			,mi.AffId
			,b.ProductId
			,SUM(ISNULL(b.Deposit, 0)		* ISNULL(e.ActualRate2, 1)) AS Deposit
			,SUM(ISNULL(b.Withdrawal, 0)	* ISNULL(e.ActualRate2, 1)) AS Withdrawal
			,SUM(ISNULL(b.Bonus, 0)			* ISNULL(e.ActualRate2, 1)) AS Bonus
			,SUM(ISNULL(b.Adjustment, 0)	* ISNULL(e.ActualRate2, 1)) AS Adjustment
			,SUM(ISNULL(b.Turnover, 0)		* ISNULL(e.ActualRate2, 1)) AS Turnover
			,SUM(ISNULL(b.Winloss, 0)		* ISNULL(e.ActualRate2, 1)) AS Winloss
			,e.ActualRate
			,e.ActualRate2
		FROM #tmpBettrans b
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.custid = mi.IBCCustID
			CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(mi.currency, b.winlostdate) e
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, b.WinlostDate) + 1, 0))
					AND mr.IBCCustId = mi.IBCCustId
				)
		GROUP BY
			mi.IBCCustId
			,mi.Currency
			,mi.AffId
			,b.ProductId
			,e.ActualRate
			,e.ActualRate2

		DROP TABLE #_recommend
		DROP TABLE #tmpBettrans
	END

	-- Gen data into rptMemberDaily
	BEGIN
		MERGE dbo.rptMemberDaily AS TARGET
		USING #rptMemberDaily AS SOURCE
			ON		TARGET.WinlostDate	= @WinlostDate
				AND TARGET.IBCCustId	= SOURCE.IBCCustId
				AND TARGET.ProductId	= SOURCE.ProductId
		WHEN MATCHED THEN
			UPDATE SET
				TARGET.Currency		= SOURCE.Currency
				,TARGET.AffId		= SOURCE.AffId
				,TARGET.Deposit		= SOURCE.Deposit
				,TARGET.Withdrawal	= SOURCE.Withdrawal
				,TARGET.Bonus		= SOURCE.Bonus
				,TARGET.Adjustment	= SOURCE.Adjustment
				,TARGET.Turnover	= SOURCE.Turnover
				,TARGET.Winloss		= SOURCE.Winloss
				,TARGET.AWinloss	= 0
				,TARGET.AComm		= 0
				,TARGET.AffExRate	= SOURCE.AffExRate
				,TARGET.ExRate		= SOURCE.ExRate
		WHEN NOT MATCHED BY TARGET THEN
			INSERT
			(
				WinlostDate,IBCCustId,Currency,AffId,ProductId,
				Deposit,Withdrawal,Bonus,Adjustment,
				Turnover,Winloss,AWinloss,AComm,AffExRate,ExRate
			)
			VALUES
			(
				@WinlostDate,SOURCE.IBCCustId,SOURCE.Currency,SOURCE.AffId,SOURCE.ProductId,
				SOURCE.Deposit,SOURCE.Withdrawal,SOURCE.Bonus,SOURCE.Adjustment,
				SOURCE.Turnover,SOURCE.Winloss,0,0,SOURCE.AffExRate,SOURCE.ExRate
			)
		WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @WinlostDate AND TARGET.ProductId IN (SELECT ProductId FROM #_bettype) THEN
			DELETE;
	END

	DROP TABLE #rptMemberDaily
END
GO