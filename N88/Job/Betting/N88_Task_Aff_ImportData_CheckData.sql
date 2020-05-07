/*<info serverAlias="DBAFFN88-Affiliate_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData]
	@WinlostDate	SMALLDATETIME,
	@IsCheckOnly	BIT = 0,
	@IsMatched		BIT = 0 OUTPUT,
	@ProductList	VARCHAR(50) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Job - Check and regen data of IBC's Products

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	DECLARE @MBBUDate TABLE (MoveBetsDay SMALLDATETIME, BalanceUpDay SMALLDATETIME)
	
	INSERT INTO @MBBUDate (MoveBetsDay, BalanceUpDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay
	FROM @MBBUDate

	IF @WinlostDate IS NULL OR @WinlostDate NOT BETWEEN @BalanceUpDay AND @MoveBetsDay
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
		
		CREATE TABLE #_bettype (ProductId INT, bettype SMALLINT)
		INSERT INTO #_bettype (ProductId, bettype)
		SELECT DISTINCT p.ProductId, s.bettype -- bet types of bet tickets
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
			
		CREATE TABLE #_recommend (recommend INT)
		INSERT INTO #_recommend (recommend)
		SELECT DISTINCT recommend
		FROM dbo.MemberInfo WITH (NOLOCK)
			
		INSERT INTO #tmpBettrans (custid, winlostdate, ProductId, Deposit, Withdrawal, Bonus, Adjustment, Turnover, Winloss)
		SELECT b.custid, b.winlostdate, CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END AS ProductId
			,SUM(CASE WHEN bt.ProductId = -1 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Deposit
			,SUM(CASE WHEN bt.ProductId = -2 THEN -(b.winlost-b.actual_stake)	ELSE 0 END) AS Withdrawal
			,SUM(CASE WHEN bt.ProductId = -3 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Bonus
			,SUM(CASE WHEN bt.ProductId = -4 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Adjustment
			,SUM(CASE WHEN bt.ProductId > 0 AND b.bettype <> 911 THEN b.stake	ELSE 0 END) AS Turnover
			,SUM(CASE WHEN bt.ProductId > 0 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS Winloss
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
			INNER JOIN #_recommend r ON b.recommend = r.recommend
			INNER JOIN #_bettype bt ON b.bettype = bt.bettype
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 103)
		GROUP BY b.custid, b.winlostdate, CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END

		DROP TABLE #_recommend

		CREATE TABLE #rptMemberDaily
		(
			CustId			INT
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
		)
		INSERT INTO #rptMemberDaily
		(
			CustId
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
		)
		SELECT
			mi.CustId
			,mi.Currency
			,mi.AffId
			,b.ProductId
			,SUM(ISNULL(b.Deposit, 0)) AS Deposit
			,SUM(ISNULL(b.Withdrawal, 0)) AS Withdrawal
			,SUM(ISNULL(b.Bonus, 0)) AS Bonus
			,SUM(ISNULL(b.Adjustment, 0)) AS Adjustment
			,SUM(ISNULL(b.Turnover, 0)) AS Turnover
			,SUM(ISNULL(b.Winloss, 0)) AS Winloss
			,e.Rate
		FROM #tmpBettrans b
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.custid = mi.IBCCustId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.winlostdate, mi.currency, 0) e
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, b.WinlostDate) + 1, 0))
					AND mr.CustId = mi.CustId
				)
		GROUP BY
			mi.CustId
			,mi.Currency
			,mi.AffId
			,b.ProductId
			,e.Rate

		DROP TABLE #tmpBettrans
	END

	-- Compare data
	BEGIN
		CREATE TABLE #_CheckData
		(
			ModifiedType	INT
			,CustId			INT
			,ProductId		INT
			,AffId			INT
			,Currency		INT
			,AffExRate		FLOAT
			,Bonus			MONEY
			,Turnover		MONEY
			,Winloss		MONEY
			,Deposit		MONEY
			,Withdrawal		MONEY
			,Adjustment		MONEY
		)
		;WITH CTE_rptMemberDaily AS
		(
			SELECT AffId,CustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate
				AND ProductId IN (SELECT ProductId FROM #_bettype)
		)
		INSERT INTO #_CheckData (ModifiedType, CustId, ProductId, AffId, Currency, AffExRate, Bonus, Turnover, Winloss, Deposit, Withdrawal, Adjustment)
		SELECT
			CASE	WHEN t.CustId IS NULL THEN -1 -- delete
					WHEN r.CustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType -- update
			,ISNULL(t.CustId, r.CustId) AS CustId
			,ISNULL(t.ProductId, r.ProductId) AS ProductId
			,t.AffId, t.Currency, t.AffExRate, t.Bonus, t.Turnover, t.Winloss
			,t.Deposit, t.Withdrawal, t.Adjustment
		FROM #rptMemberDaily t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.CustId = r.CustId AND t.ProductId = r.ProductId

		IF @@ROWCOUNT = 0
			SELECT @IsMatched = 1
		ELSE
			SELECT @IsMatched = 0
	END

	-- Correct data
	IF @IsMatched = 0
	BEGIN
		IF @IsCheckOnly = 1
		BEGIN
			PRINT 'Data on rptMemberDaily is not matched with source. ' + 'WinlostDate = ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
			RETURN
		END
		
		-- Delete
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.CustId = r.CustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = -1

			DELETE #_CheckData WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 1)
		BEGIN
			DELETE #_CheckData
			OUTPUT @WinlostDate,DELETED.AffId,DELETED.CustId,DELETED.ProductId
					,DELETED.Deposit,DELETED.Withdrawal,DELETED.Bonus,DELETED.Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.AffExRate
			INTO dbo.rptMemberDaily(WinlostDate,AffId,CustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate)
			WHERE ModifiedType = 1
		END

		-- Update
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 0)
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.AffId = d.AffId
				,r.Deposit = d.Deposit
				,r.Withdrawal = d.Withdrawal
				,r.Bonus = d.Bonus
				,r.Adjustment = d.Adjustment
				,r.Turnover = d.Turnover
				,r.Winloss = d.Winloss
				,r.Currency = d.Currency
				,r.AffExRate = d.AffExRate
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.CustId = r.CustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = 0
				AND (
					r.AffId						<> d.AffId
					OR ISNULL(r.Bonus, 0)		<> ISNULL(d.Bonus, 0)
					OR ISNULL(r.Turnover, 0)	<> ISNULL(d.Turnover, 0)
					OR ISNULL(r.Winloss, 0)		<> ISNULL(d.Winloss, 0)
					OR ISNULL(r.Deposit, 0)		<> ISNULL(d.Deposit, 0)
					OR ISNULL(r.Withdrawal, 0)	<> ISNULL(d.Withdrawal, 0)
					OR ISNULL(r.Adjustment, 0)	<> ISNULL(d.Adjustment, 0)
					OR ISNULL(r.Currency, 0)	<> ISNULL(d.Currency, 0)
					OR ISNULL(r.AffExRate, 0)	<> ISNULL(d.AffExRate, 0)
				)
		END
	END

	-- Output data
	SELECT @ProductList = NULL
	SELECT @ProductList = COALESCE(@ProductList + ',', '') + CONVERT(VARCHAR(5), ProductId) FROM #_CheckData

	DROP TABLE #_bettype
	DROP TABLE #_CheckData
	DROP TABLE #rptMemberDaily
END
GO