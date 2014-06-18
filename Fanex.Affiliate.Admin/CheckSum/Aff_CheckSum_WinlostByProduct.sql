ALTER PROCEDURE [dbo].[Aff_CheckSum_WinlostByProduct] 
	@Xml XML
	,@Prefix VARCHAR(100)
	,@Date SMALLDATETIME
AS
/*
Created: 20140529@bobby
Task : #1052 -  Create a daily checksum data service
DB: DB054/DB052.bodb02
Original : [Aff_PlayersWinlostByProductSel]  
Revisions:  

Param's Explanation:  
	@Xml: format '<root>
		<trans username="train1991"></trans>
		<trans_N username="XXX"></trans>
	</root>'
*/
BEGIN
	SET NOCOUNT ON;
	SET @Date = CAST(@Date AS DATE)

	CREATE TABLE #LicenseeCust (
		custID INT
		,username VARCHAR(100)
		,srecommend INT
		,mrecommend INT
		,recommend INT
		)

	DECLARE @CutDate_LIC DATETIME
		,@MaxDate_LIC DATETIME
		,@CutDate_RPT DATETIME
		,@MaxDate_RPT DATETIME

	SELECT @CutDate_LIC = MIN(winlostdate)
		,@MaxDate_LIC = MAX(Winlostdate)
	FROM bodb_licensee.dbo.rptLicWinloss2 WITH (NOLOCK)

	SELECT @CutDate_RPT = MIN(winlostdate)
		,@MaxDate_RPT = MAX(Winlostdate)
	FROM DBRPT.bodb_report.dbo.rptdepwinlost WITH (NOLOCK)

	CREATE TABLE #tmpBettrans (
		Winlostdate SMALLDATETIME
		,ProductID INT
		,Turnover MONEY
		,TurnoverNoDraw MONEY
		,Outstanding MONEY
		,Winloss MONEY
		,PlayerComm MONEY
		,BetCount INT
		,BetCountNoDraw INT
		)

	CREATE TABLE #tmpFunding (
		Winlostdate SMALLDATETIME
		,ProductID INT DEFAULT(0)
		,Deposit MONEY
		,Withdrawal MONEY
		,Bonus MONEY
		,Adjustment MONEY
		)

	DECLARE @TempTrans TABLE (UserName VARCHAR(30))

	INSERT INTO @TempTrans (UserName) --Convert xml to table
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS UserName
	FROM @Xml.nodes('/root/trans') AS [Table]([Column])

	INSERT INTO #LicenseeCust
	SELECT c.CustID
		,t.UserName
		,c.srecommend
		,c.mrecommend
		,c.recommend
	FROM bodb02.dbo.customer c WITH (NOLOCK)
		INNER JOIN @TempTrans AS t
		ON @Prefix + t.username = c.username2
	WHERE c.roleid = 1

	-- import all products
	IF @Date > @MaxDate_LIC
	BEGIN
		-- insert member bet tincket
		INSERT INTO #tmpBettrans (
			Winlostdate
			,ProductID
			,Turnover
			,Outstanding
			,Winloss
			,PlayerComm
			,BetCount
			,TurnoverNoDraw
			,BetCountNoDraw
			)
		SELECT b.winlostdate
			,CASE 
				WHEN bettype IN (71, 72) THEN 251 --casino
				WHEN bettype = 1000 THEN 253 --games
				WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN 151 -- Horse Racing
				WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
				WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
				WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport	
				WHEN bettype BETWEEN 51 AND 69 THEN 201 -- Financial	
				WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno  
				WHEN b.bettype < 31
					OR (b.bettype BETWEEN 121 AND 999) THEN 0 -- sportsbook
				ELSE - 1
				END
			,-- undefined productid
			SUM(b.stake)
			,--Turnover  
			SUM(CASE 
					WHEN ruben = 0 THEN actual_stake
					ELSE 0
					END)
			,--Outstanding  
			SUM(CASE 
					WHEN ruben = 1 THEN b.winlost - b.actual_stake
					ELSE 0
					END)
			,--Winloss      
			SUM(CASE 
					WHEN ruben = 1 THEN b.playercomm
					ELSE 0
					END)
			,--Playercomm      
			COUNT(1)
			,--betcount
			SUM(stake * CASE 
					WHEN statusID = 111 THEN 0
					WHEN (
							b.statusID = 112
							OR b.statusID = 113
							)
						AND ABS(modds) = 0.25
						AND b.bettype IN (1, 3, 7, 8, 17, 18)
						AND (
							b.bettype < 31
							OR (b.bettype BETWEEN 121 AND 999)
							) THEN 0.5 -- sportsbook rules
					WHEN (
							b.statusID = 112
							OR b.statusID = 113
							)
						AND b.liveawayscore = 0
						AND b.bettype IN (33, 43) THEN 0.5 -- Racing rules
					ELSE 1
					END)
			,-- Turnover No Draw
			SUM(CASE 
					WHEN b.statusID = 111 THEN 0
					ELSE 1
					END)
		FROM bodb02.dbo.bettrans b WITH (NOLOCK, INDEX (IX_recommend_transid))
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
				AND b.recommend = c.recommend
		WHERE b.winlostdate = @date
			AND bettype < 19999
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'      
		GROUP BY b.winlostdate
			,CASE 
				WHEN bettype IN (71, 72) THEN 251 --casino
				WHEN bettype = 1000 THEN 253 --games
				WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN 151 -- Horse Racing
				WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
				WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
				WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport	
				WHEN bettype BETWEEN 51 AND 69 THEN 201 -- Financial
				WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno  
				WHEN b.bettype < 31
					OR (b.bettype BETWEEN 121 AND 999) THEN 0 -- sportsbook 
				ELSE - 1
				END;
	END
	ELSE IF @Date < @CutDate_LIC
	BEGIN
		INSERT INTO #tmpBettrans (
			Winlostdate
			,ProductID
			,Turnover
			,Outstanding
			,Winloss
			,PlayerComm
			,BetCount
			,TurnoverNoDraw
			,BetCountNoDraw
			)
		SELECT b.winlostdate 
			,b.Sporttype
			,SUM(b.turnover)
			,0 AS Outstanding
			,SUM(b.winlost)
			,SUM(b.playercomm)
			,SUM(b.BetCount)
			,SUM(CASE 
					WHEN (
							b.statusID = 112
							OR b.statusID = 113
							) THEN turnover
					WHEN (
							b.statusID = 114
							OR b.statusID = 115
							) THEN turnover / 2
					ELSE 0
					END)
			,SUM(CASE 
					WHEN b.statusID = 111 THEN 0
					ELSE BetCount
					END) -- Betcount No Draw
		FROM bodb_licensee.dbo.rptLicWinloss_old b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
				AND b.recommend = c.recommend
				AND b.srecommend = c.srecommend
		WHERE b.winlostdate = @Date
			AND b.BetCount > 0
			AND b.roleid = 1
			AND b.sporttype IN (0, 151, 161, 162, 180, 201, 251, 253, 202)
			-- and b.isBA=0
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,b.Sporttype;
	END
	ELSE IF @Date >= @CutDate_LIC
	BEGIN
		INSERT INTO #tmpBettrans (
			Winlostdate
			,ProductID
			,Turnover
			,Outstanding
			,Winloss
			,PlayerComm
			,BetCount
			,TurnoverNoDraw
			,BetCountNoDraw
			)
		SELECT b.winlostdate 
			,b.Sporttype
			,sum(b.turnover)
			,0 AS Outstanding
			,sum(b.winlost)
			,sum(b.playercomm)
			,sum(b.BetCount)
			,SUM(CASE 
					WHEN (
							b.statusID = 112
							OR b.statusID = 113
							) THEN turnover
					WHEN (
							b.statusID = 114
							OR b.statusID = 115
							) THEN turnover / 2
					ELSE 0
					END)
			,SUM(CASE 
					WHEN b.statusID = 111 THEN 0
					ELSE BetCount
					END) -- Betcount No Draw
		FROM bodb_licensee.dbo.rptLicWinloss2 b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
				AND b.recommend = c.recommend
				AND b.srecommend = c.srecommend
		WHERE b.winlostdate = @Date
			AND b.BetCount > 0
			AND b.roleid = 1
			AND b.sporttype IN (0, 151, 161, 162, 180, 201, 251, 253, 202)
			-- and b.isBA=0
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,b.Sporttype;
	END

	-- import PlaytechCS product
	INSERT INTO #tmpBettrans (
		Winlostdate
		,ProductID
		,Turnover
		,Outstanding
		,Winloss
		,PlayerComm
		,BetCount
		,TurnoverNoDraw
		,BetCountNoDraw
		)
	SELECT b.winlostdate
		,b.Sporttype
		,SUM(ISNULL(b.turnover, 0)) AS Turnover
		,SUM(ISNULL(Outstanding, 0)) AS Outstanding
		,SUM(ISNULL(b.winlost, 0)) AS Winloss
		,SUM(ISNULL(b.playercomm, 0))AS PlayerComm
		,SUM(ISNULL(b.BetCount, 0)) AS BetCount
		,SUM((ISNULL(b.turnover,0) - ISNULL(b.drawTO,0))) AS TurnoverNoDraw
		,SUM((ISNULL(b.BetCount,0) - ISNULL(drawBetCount,0))) AS BetCountNoDraw
	FROM DBRPT.bodb_report.dbo.rptDepWinlost_PlaytechCS b WITH (NOLOCK)
		INNER JOIN #LicenseeCust c WITH (NOLOCK)
		ON b.custid = c.custid
	WHERE b.winlostdate = @Date
		AND sporttype = 254
		AND b.BetCount > 0
	GROUP BY b.winlostdate
		,b.Sporttype

	-- import funding data
	IF DATEDIFF(d, @Date, CURRENT_TIMESTAMP) <= 1
	BEGIN
		INSERT INTO #tmpFunding (
			Winlostdate
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			)
		SELECT b.winlostdate
			,SUM(CASE 
					WHEN bettype = 22001 THEN winlost - actual_stake
					ELSE 0
					END) AS Deposit
			,- SUM(CASE 
					WHEN bettype IN (22002, 22003) THEN winlost - actual_stake
					ELSE 0
					END) AS Withdrawal
			,SUM(CASE 
					WHEN bettype = 22004 THEN winlost - actual_stake
					ELSE 0
					END) AS Bonus
			,SUM(CASE 
					WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN winlost - actual_stake
					ELSE 0
					END) AS Adjustment
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
		WHERE b.winlostdate = @Date
			AND b.custid > 0
			AND bettype IN (22001, 22002, 22003, 22004, 22005, 22006, 22007, 21001, 21002, 21003, 21004, 21005, 21006)
		GROUP BY b.winlostdate
	END
	ELSE IF @Date < @CutDate_RPT
	BEGIN
		INSERT INTO #tmpFunding (
			Winlostdate
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			)
		SELECT b.winlostdate
			,SUM(isnull(b.deposit, 0)) AS Deposit
			,SUM(isnull(b.withdrawal, 0)) AS Withdrawal
			,SUM(isnull(b.Bonus, 0)) AS Bonus
			,SUM(isnull(b.Adjustment, 0)) AS Adjustment
		FROM DBRPT.bodb_report.dbo.rptDepWinlost_bk b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
		WHERE b.winlostdate = @Date
			AND (
				isnull(b.deposit, 0) <> 0
				OR isnull(b.withdrawal, 0) <> 0
				OR isnull(b.Bonus, 0) <> 0
				OR isnull(b.Adjustment, 0) <> 0
				)
		GROUP BY b.winlostdate
	END
	ELSE IF @Date >= @CutDate_RPT
	BEGIN
		INSERT INTO #tmpFunding (
			Winlostdate
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			)
		SELECT b.winlostdate
			,SUM(isnull(b.deposit, 0)) AS Deposit
			,SUM(isnull(b.withdrawal, 0)) AS Withdrawal
			,SUM(isnull(b.Bonus, 0)) AS Bonus
			,SUM(isnull(b.Adjustment, 0)) AS Adjustment
		FROM DBRPT.bodb_report.dbo.rptdepwinlost b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
		WHERE b.winlostdate = @Date
			AND (
				isnull(b.deposit, 0) <> 0
				OR isnull(b.withdrawal, 0) <> 0
				OR isnull(b.Bonus, 0) <> 0
				OR isnull(b.Adjustment, 0) <> 0
				)
		GROUP BY b.winlostdate
	END
	
	-- fetch final result
	;WITH rptProduct AS (
		SELECT TOP 1 0 AS ProductID 
			,@Date AS Winlostdate
		FROM #tmpFunding
		UNION
		SELECT ProductID
			,@Date AS Winlostdate
		FROM #tmpBettrans
		GROUP BY ProductID
	)
	SELECT p.Winlostdate
		,p.ProductID
		,ISNULL(f.Deposit, 0) Deposit
		,ISNULL(f.Withdrawal, 0) Withdrawal
		,ISNULL(f.Bonus, 0) Bonus
		,ISNULL(f.Adjustment, 0) Adjustment
		,ISNULL(b.Turnover, 0) Turnover
		,ISNULL(b.Outstanding, 0) Outstanding
		,ISNULL(b.Winloss, 0) Winloss
		,ISNULL(b.PlayerComm, 0) PlayerComm
		,ISNULL(b.BetCount, 0) BetCount
		,ISNULL(b.TurnoverNoDraw, 0) TurnoverNoDraw
		,ISNULL(b.BetCountNoDraw, 0) BetCountNoDraw
	INTO #rptData
	FROM rptProduct p
		LEFT JOIN #tmpFunding AS f 
		ON p.ProductID = f.ProductID AND p.Winlostdate = f.Winlostdate
		LEFT JOIN #tmpBettrans b
		ON p.ProductID = b.ProductID AND p.Winlostdate = b.Winlostdate

	-- product detail
	SELECT Winlostdate
		,ProductID
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Outstanding
		,Winloss
		,PlayerComm
		,BetCount
		,TurnoverNoDraw
		,BetCountNoDraw 
	FROM #rptData

	--sum total
	SELECT  Winlostdate
		,SUM(Deposit) AS TotalDeposit
		,SUM(Withdrawal) AS TotalWithdrawal
		,SUM(Bonus) AS TotalBonus
		,SUM(Adjustment) AS TotalAdjustment
		,SUM(Turnover) AS TotalTurnover
		,SUM(Outstanding) AS TotalOutstanding
		,SUM(Winloss) AS TotalWinloss
		,SUM(PlayerComm) AS TotalPlayerComm
		,SUM(BetCount) AS TotalBetCount
		,SUM(TurnoverNoDraw) AS TotalTurnoverNoDraw
		,SUM(BetCountNoDraw) AS TotalBetCountNoDraw
	FROM #rptData
	GROUP BY Winlostdate

	-- drop tables
	DROP TABLE #rptData

	DROP TABLE #tmpBettrans

	DROP TABLE #tmpFunding

	DROP TABLE #LicenseeCust
END
GO
GRANT EXECUTE ON [dbo].[Aff_CheckSum_WinlostByProduct] TO [bodbAdminNet] AS [dbo]
--exec [dbo].[Aff_CheckSum_WinlostByProduct] 
--	@Xml = '<root>
--		<trans username="LBUUSMem001"></trans>
--	</root>'
--	,@Prefix  = 'LiveBet365$'
--	,@Date  = '2014-05-19 00:00:00'