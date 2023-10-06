/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220628@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: re gen data for BITCOIN
*/

SET NOCOUNT ON

DECLARE @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME, @WinlostDate DATETIME, @ProductId INT 
DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

CREATE TABLE #tmpBettrans 
(
	winlostdate SMALLDATETIME
	,custid		INT
	,ProductId	INT
	,Deposit	MONEY
	,Withdrawal MONEY
	,Bonus		MONEY
	,Adjustment MONEY
	,Turnover	MONEY
	,Winloss	MONEY
)

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

CREATE TABLE #_recommend (recommend INT)

INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
EXEC bodb02.dbo.Age_SelBalanceUpDay

SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @tblMoveBetBalanceUp
SELECT @ProductId = ProductId FROM Products WITH(NOLOCK) WHERE ProductName = 'Bitcoin'

INSERT INTO #_recommend (recommend)
SELECT DISTINCT recommend
FROM dbo.MemberInfo WITH (NOLOCK)

SET @WinlostDate = '2022-06-01'

WHILE @WinlostDate <= '2022-06-30'
BEGIN
	TRUNCATE TABLE #tmpBettrans
	TRUNCATE TABLE #rptMemberDaily

	IF @WinlostDate > @MoveBetsDay
	BEGIN
		INSERT INTO #tmpBettrans (custid, winlostdate, ProductId, Deposit, Withdrawal, Bonus, Adjustment, Turnover, Winloss)
		SELECT b.custid, @WinlostDate, @ProductId AS ProductId
			,0 AS Deposit
			,0 AS Withdrawal
			,0 AS Bonus
			,0 AS Adjustment
			,SUM(b.stake) AS Turnover
			,SUM(b.winlost-b.actual_stake+b.playercomm) AS Winloss
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #_recommend r ON b.recommend = r.recommend
		WHERE b.winlostdate = @WinlostDate AND b.bettype = 7901
			AND b.statusID NOT IN (0, 1, 101, 102, 103)
		GROUP BY b.custid
	END
	ELSE
	BEGIN
		INSERT INTO #tmpBettrans (custid, winlostdate, ProductId, Deposit, Withdrawal, Bonus, Adjustment, Turnover, Winloss)
		SELECT b.custid, @WinlostDate, @ProductId AS ProductId
			,0 AS Deposit
			,0 AS Withdrawal
			,0 AS Bonus
			,0 AS Adjustment
			,SUM(b.turnover) AS Turnover
			,SUM(b.winlost + b.playercomm) AS Winloss
		FROM bodb_LicenseeReport.dbo.rptLicWinloss2 b WITH (NOLOCK)
			INNER JOIN #_recommend r ON b.recommend = r.recommend
		WHERE b.winlostdate = @WinlostDate AND b.sporttype = 175
			AND b.statusID NOT IN (0, 1, 101, 102, 103)
			AND b.roleid = 1
		GROUP BY b.custid
	END

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
		,0 AS Deposit
		,0 AS Withdrawal
		,0 AS Bonus
		,0 AS Adjustment
		,SUM(ISNULL(b.Turnover, 0)) AS Turnover
		,SUM(ISNULL(b.Winloss, 0)) AS Winloss
		,e.ActualRate2
		,e.ActualRate
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
		,e.ActualRate2
		,e.ActualRate

	IF EXISTS (SELECT 1 FROM dbo.rptMemberDaily WITH(NOLOCK) WHERE WinlostDate = @WinlostDate AND ProductId = @ProductId)
	BEGIN
		DELETE rptMemberDaily WITH(ROWLOCK, UPDLOCK)
		WHERE WinlostDate = @WinlostDate AND ProductId = @ProductId

		PRINT 'Delete data on '+ CONVERT(VARCHAR(50), @WinlostDate, 120) + ' for productid = ' + CONVERT(VARCHAR(50), @ProductId)
	END

	
	INSERT INTO dbo.rptMemberDaily
	(
		WinlostDate
		,AffId
		,IBCCustId
		,ProductId
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Winloss
		,Currency
		,ExRate
		,AffExRate
		,AWinloss
		,AComm
	)
	SELECT 
		@WinlostDate
		,AffId
		,IBCCustId
		,ProductId
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Winloss
		,Currency
		,ExRate
		,AffExRate
		,0
		,0
	FROM #rptMemberDaily

	PRINT 'Finished creating data on ' + CONVERT(VARCHAR(50), @WinlostDate, 120)
	SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	
	WAITFOR DELAY '00:00:00.280'

END

DROP TABLE #tmpBettrans
DROP TABLE #_recommend
DROP TABLE #rptMemberDaily

SET NOCOUNT OFF

