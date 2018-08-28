/*<info serverAlias="DBEXT-bodb02" executers="" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_Bettrans]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBEXT.bodb02
	Task: Job - Get data on bettrans

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN 
	SET NOCOUNT ON 
	
	-- Agent Info
	BEGIN
		DECLARE @recommend TABLE (recommend INT)

		/*
		INSERT INTO @recommend (recommend)
		SELECT recommend FROM OPENQUERY (DBAFF12BET, 'SELECT DISTINCT recommend FROM Affiliate_12BET.dbo.MemberInfo WITH (NOLOCK)')
		*/

		INSERT INTO @recommend (recommend)
		SELECT DISTINCT ci.recommend
		FROM dbo.Aff_f_GetTestingCustId() c
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
		WHERE ci.roleId = 1
	END

	-- Get SportBettypeMatrix Info
	BEGIN
		CREATE TABLE #SportBettypeMatrix (ProductId INT, ProductPrefix VARCHAR(10), Bettype INT)
	
		INSERT INTO #SportBettypeMatrix (ProductPrefix, Bettype)
		SELECT DISTINCT p.ProductPrefix, s.BetType
		FROM dbo.Products p WITH (NOLOCK)
			INNER JOIN dbo.SportBettypeMatrix s WITH (NOLOCK) ON p.ProductID = s.ProductID
		WHERE s.BetType NOT IN (912, 913, 914) -- Exclude CashOut (keep 911)

		-- Transfer tickets
		INSERT INTO #SportBettypeMatrix (ProductId, Bettype)
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

		UPDATE s
		SET s.ProductId = p.ProductId
		FROM #SportBettypeMatrix s
			INNER JOIN (
				SELECT ProductId, ProductPrefix
				FROM OPENQUERY (DBAFF12BET, 'SELECT ProductId, ProductPrefix
											 FROM Affiliate_12BET.dbo.Products WITH (NOLOCK)
											 WHERE IsIBC = 1')
			) AS p ON s.ProductPrefix = p.ProductPrefix
		WHERE s.ProductPrefix IS NOT NULL

		-- For CashOut
		UPDATE #SportBettypeMatrix
		SET ProductId = 1
		WHERE Bettype = 911

		DELETE #SportBettypeMatrix
		WHERE ProductId IS NULL
	END

	-- Get Data from bettrans
	BEGIN
		SELECT
			custid,
			currency,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			Turnover,
			Winloss
		FROM
		(
			SELECT
				b.custid,
				b.currency,
				CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END AS ProductId,
				SUM(CASE WHEN bt.ProductId = -1 THEN b.winlost-b.actual_stake ELSE 0 END) AS Deposit,
				SUM(CASE WHEN bt.ProductId = -2 THEN -(b.winlost-b.actual_stake) ELSE 0 END) AS Withdrawal,
				SUM(CASE WHEN bt.ProductId = -3 THEN b.winlost-b.actual_stake ELSE 0 END) AS Bonus,
				SUM(CASE WHEN bt.ProductId = -4 THEN b.winlost-b.actual_stake ELSE 0 END) AS Adjustment,
				SUM(CASE WHEN bt.ProductId > 0 AND bt.ProductPrefix <> 'CO' THEN b.stake ELSE 0 END) AS Turnover,
				SUM(CASE WHEN bt.ProductId > 0 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS Winloss
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN #SportBettypeMatrix bt WITH (NOLOCK) ON b.bettype = bt.Bettype
				CROSS APPLY @recommend r
			WHERE
				b.recommend = r.recommend
				AND b.winlostdate = @WinlostDate
				AND b.statusID NOT IN (0, 1, 101, 102, 103)
			GROUP BY
				b.custid,
				b.currency,
				CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END
		) AS A
		WHERE EXISTS (SELECT 1 FROM dbo.Aff_f_GetTestingCustId() c WHERE c.CustId = A.CustId)
	END

	DROP TABLE #SportBettypeMatrix
END
GO