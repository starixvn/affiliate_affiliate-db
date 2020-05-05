/*<info serverAlias="DBAFFN8B-Affiliate_N8B" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData]
	@WinlostDate	SMALLDATETIME,
	@IsCheckOnly	BIT = 0,
	@IsMatched		BIT = 0 OUTPUT,
	@ProductList	VARCHAR(50) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
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
		)
		SELECT
			mi.IBCCustId
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
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.custid = mi.IBCCustID
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.winlostdate, mi.currency, 0) e
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
			,e.Rate

		DROP TABLE #tmpBettrans
	END

	-- Compare data
	BEGIN
		CREATE TABLE #_CheckData
		(
			ModifiedType	INT
			,IBCCustId		INT
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
			SELECT AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate
				AND ProductId IN (SELECT ProductId FROM #_bettype)
		)
		INSERT INTO #_CheckData (ModifiedType, IBCCustId, ProductId, AffId, Currency, AffExRate, Bonus, Turnover, Winloss, Deposit, Withdrawal, Adjustment)
		SELECT
			CASE	WHEN t.IBCCustId IS NULL THEN -1 -- delete
					WHEN r.IBCCustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType -- update
			,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
			,ISNULL(t.ProductId, r.ProductId) AS ProductId
			,t.AffId, t.Currency, t.AffExRate, t.Bonus, t.Turnover, t.Winloss
			,t.Deposit, t.Withdrawal, t.Adjustment
		FROM #rptMemberDaily t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.IBCCustId = r.IBCCustId AND t.ProductId = r.ProductId

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
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = -1

			DELETE #_CheckData WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 1)
		BEGIN
			DELETE #_CheckData
			OUTPUT @WinlostDate,DELETED.AffId,DELETED.IBCCustId,DELETED.ProductId
					,DELETED.Deposit,DELETED.Withdrawal,DELETED.Bonus,DELETED.Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.AffExRate
			INTO dbo.rptMemberDaily(WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate)
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
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = 0
				AND (
					r.AffId <> d.AffId
					OR r.Bonus <> d.Bonus
					OR r.Turnover <> d.Turnover
					OR r.Winloss <> d.Winloss
					OR r.Deposit <> d.Deposit
					OR r.Withdrawal <> d.Withdrawal
					OR r.Adjustment <> d.Adjustment
					OR r.Currency <> d.Currency
					OR r.AffExRate <> d.AffExRate
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