/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
 
ALTER PROCEDURE [dbo].[Aff_CheckSum_WinlostByProduct] 
	@Xml 			XML
	,@Prefix 		VARCHAR(100)
	,@Date 			SMALLDATETIME
	,@ProductIDs 	VARCHAR(100) 	= NULL
	,@Separator		CHAR(1) 		= ','
AS

/*
Created: 20140529@bobby
Task : #1052 -  Create a daily checksum data service
DB: DB054/DB052.bodb02
Original : [Aff_PlayersWinlostByProductSel]  
Revisions:  
	- 20140820@Bobby: Add filtering by ProductIDs
	- 20161022@Jim:move table to bodb_licenseereport [RedmineID :#60449]
	- 20161110@Bobby: #67071 - Correct productid for funding data
	- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
	- 20180629@Percy: Get member data by sporttype after movebetday [RedmineID: #97592]
	
Param's Explanation:  
	@Xml: 
	</root>'
	- @Xml: List member's username is under affiliate user
		+ Example: '<root>
		<trans username="train1991"></trans>
		<trans_N username="XXX"></trans></root>
	- @Prefix: Is the Licensee Name as default plus ($) sign
	- @Date: Date only
	- @ProductIDs: IBC product ID
		+ 1:	Sportsbook
		+ 2: 	RNG Casino	
		+ 3:	Number Game
		+ 4:	Live Casino
		+ 5:	Virtual Sports
		+ 6:	RNG Casino
		+ 8:	Keno
		+ 11:	AG Casino
		+ 12:	Gold Deluxe
		+ 14:	Macau
*/

BEGIN
	SET NOCOUNT ON;

	SELECT @Date = CAST(@Date AS DATE)
		,@ProductIDs = ISNULL(@ProductIDs, '')
		
	CREATE TABLE #LicenseeCust (
		custID INT
		,username VARCHAR(100)
		,srecommend INT
		,mrecommend INT
		,recommend INT
		,CO_WL_Share	DECIMAL(9,8)
		)
	-- Do filtering product 
	CREATE TABLE #ProductBettype (
		ProductId 		TINYINT
		, Bettype		SMALLINT
	)
	CREATE TABLE #ProductSporttype (
		ProductId INT
	   ,Sporttype SMALLINT
	)

	DECLARE @ProductFilter TABLE (ProductId TINYINT)
	INSERT INTO @ProductFilter ( ProductId )
	SELECT CAST(val AS TINYINT) AS ProductId 
	FROM [dbo].[strSplit_Key](@ProductIDs, ',')
	
	INSERT INTO #ProductBettype (
		ProductId
		, Bettype
	)
	SELECT DISTINCT p.ProductId
		, Bettype
	FROM dbo.SportBettypeMatrix bt WITH(NOLOCK)
		INNER JOIN @ProductFilter p
		ON bt.ProductId = p.ProductId
	WHERE bt.IsTest 	= 0
		AND bt.Enabled 	= 1

	INSERT INTO #ProductBettype (
		ProductId
		, Bettype
	)
	VALUES (1, 911)

	-- insert product & Sporttype mapping
	INSERT INTO #ProductSporttype (ProductId, Sporttype)
	SELECT DISTINCT bt.ProductId, CASE WHEN bt.ProductId = 1 THEN 0 ELSE bt.Sporttype END
	FROM dbo.SportBettypeMatrix bt WITH(NOLOCK)
		INNER JOIN @ProductFilter p ON bt.ProductId = p.ProductId
	WHERE bt.IsTest = 0 AND bt.Enabled 	= 1
		
	DECLARE @CutDate_LIC DATETIME
		,@MaxDate_LIC DATETIME
		,@CutDate_RPT DATETIME
		,@MaxDate_RPT DATETIME

	SELECT @CutDate_LIC = MIN(winlostdate)
		,@MaxDate_LIC = MAX(Winlostdate)
	FROM bodb_licenseeReport.dbo.rptLicWinloss2 WITH (NOLOCK)

	SELECT @CutDate_RPT = MIN(winlostdate)
		,@MaxDate_RPT = MAX(Winlostdate)
	FROM DBRPT.bodb_report.dbo.rptdepwinlost WITH (NOLOCK)

	CREATE TABLE #tmpBettrans (
		Winlostdate SMALLDATETIME
		,ProductID TINYINT
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
		,ProductID INT DEFAULT(1)
		,Deposit MONEY
		,Withdrawal MONEY
		,Bonus MONEY
		,Adjustment MONEY
		)

	CREATE TABLE #TempTrans (UserName VARCHAR(30))

	INSERT INTO #TempTrans (UserName) --Convert xml to table
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS UserName
	FROM @Xml.nodes('/root/trans') AS [Table]([Column])

	INSERT INTO #LicenseeCust
	(
		CustID
		,UserName
		,srecommend
		,mrecommend
		,recommend
	)
	SELECT c.CustID
		,t.UserName
		,c.srecommend
		,c.mrecommend
		,c.recommend
	FROM bodb02.dbo.customer c WITH (NOLOCK)
		INNER JOIN #TempTrans AS t
		ON @Prefix + t.username = c.username2
	WHERE c.roleid = 1

	CREATE TABLE #CashOutMember (Username VARCHAR(50), DeductedPercentage DECIMAL (9,8))

	DECLARE @SQL NVARCHAR(MAX), @LastDayOfMonth DATETIME, @Database_Affiliate VARCHAR(50)

	SELECT  @Database_Affiliate = 'Affiliate_' + LEFT(@Prefix, LEN(@Prefix)-1)

	IF DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), 0) = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- current setting
	BEGIN
		SELECT @SQL =
		'SELECT UserName, DeductedPercentage
		FROM OPENQUERY(DBAFF,''SELECT mi.UserName, ds.DeductedPercentage
							FROM ' + @Database_Affiliate + '.dbo.DeductionSetting ds WITH(NOLOCK)
								INNER JOIN ' + @Database_Affiliate + '.dbo.AffInfo ai WITH(NOLOCK) ON ds.GroupID = ai.GroupID
								INNER JOIN ' + @Database_Affiliate + '.dbo.MemberInfo mi WITH(NOLOCK) ON ai.AffID = mi.AffID
							WHERE ds.DeductionID = 11'')'
	END
	ELSE
	BEGIN
		SELECT @LastDayOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date)+1, 0))

		SELECT @SQL =
		'SELECT UserName, DeductedPercentage
		FROM OPENQUERY(DBAFF,''
		SELECT mi.UserName, ds.DeductedPercentage
		FROM ' + @Database_Affiliate + '.dbo.DeductionSettingHistory ds WITH (NOLOCK)
			INNER JOIN ' + @Database_Affiliate + '.dbo.AffInfo ai WITH(NOLOCK) ON ds.GroupID = ai.GroupID
			INNER JOIN ' + @Database_Affiliate + '.dbo.MemberInfo mi WITH(NOLOCK) ON ai.AffID = mi.AffID
		WHERE ds.DeductionID = 11
			AND ds.MonthDate = ''''' + CONVERT(VARCHAR(10), @LastDayOfMonth, 120) + '''''' + ''')'
	END
	INSERT INTO #CashOutMember (Username, DeductedPercentage)
	EXEC (@SQL)

	UPDATE l
	SET l.CO_WL_Share = ISNULL(c.DeductedPercentage, 0)
	FROM #LicenseeCust l
		LEFT JOIN #CashOutMember c ON l.username = c.Username

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
			,bt.productid
			,SUM(CASE
					WHEN b.bettype = 911 THEN 0
					ELSE b.stake
					END)
			,--Turnover  
			SUM(CASE 
					WHEN ruben = 0 THEN actual_stake
					ELSE 0
					END)
			,--Outstanding  
			SUM(CASE 
					WHEN ruben = 1 THEN b.winlost - b.actual_stake
					ELSE 0
					END
				*
				CASE
					WHEN b.bettype = 911 THEN c.CO_WL_Share
					ELSE 1
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
					WHEN statusID = 111 OR b.bettype = 911 THEN 0
					WHEN (
							b.statusID = 112
							OR b.statusID = 113
							)
						AND ABS(modds) = 0.25
						AND b.bettype IN (1, 3, 7, 8, 17, 18)
						AND (
							b.bettype < 31
							OR (
								b.bettype BETWEEN 121
									AND 999
								)
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
			INNER JOIN #ProductBettype bt
			ON b.bettype = bt.bettype
			
		WHERE b.winlostdate = @date
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,bt.productid
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
			,bt.productid
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
		FROM bodb_licenseeReport.dbo.rptLicWinloss_old b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
				AND b.recommend = c.recommend
				AND b.srecommend = c.srecommend
			INNER JOIN #ProductSporttype bt
			ON b.sporttype = bt.sporttype
		WHERE b.winlostdate = @Date
			AND b.BetCount > 0
			AND b.roleid = 1
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,bt.productid
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
			,bt.productid
			,sum(CASE
					WHEN b.bettype = 911 THEN 0
					ELSE b.turnover
					END)
			,0 AS Outstanding
			,sum(b.winlost
				*
				CASE
					WHEN b.bettype = 911 THEN c.CO_WL_Share
					ELSE 1
					END)
			,sum(b.playercomm)
			,sum(b.BetCount)
			,SUM(CASE 
					WHEN b.bettype = 911 THEN 0
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
		FROM bodb_licenseeReport.dbo.rptLicWinloss2 b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK)
			ON b.custid = c.custid
				AND b.recommend = c.recommend
				AND b.srecommend = c.srecommend
			INNER JOIN #ProductSporttype bt
			ON b.sporttype = bt.sporttype
		WHERE b.winlostdate = @Date
			AND b.BetCount > 0
			AND b.roleid = 1
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,bt.productid
	END

	--AG-Casino
	IF (EXISTS (SELECT 1 FROM #ProductBettype WHERE ProductId = 11) )
	BEGIN
		DECLARE @AGCS_BackupDay 	DATE
		
		SELECT @AGCS_BackupDay 		= ISNULL(MIN(Winlostdate),'') 
		FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_AGCasino WITH(NOLOCK)
		
		IF (@Date >= @AGCS_BackupDay)-- Get data in bettrans_AGCasino table
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
			SELECT 
				Winlostdate
				,11 AS ProductID
				,SUM(Stake) AS Turnover
				,0 AS Outstanding
				,SUM(Winlost) AS Winloss
				,0 AS PlayerComm
				,COUNT(1) AS BetCount
				,SUM(CASE WHEN StatusID <> 111 THEN Stake ELSE 0 END) AS TurnoverNoDraw
				,SUM(CASE WHEN StatusID <> 111 THEN 1 ELSE 0 END) AS BetCountNoDraw
	
			FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH(NOLOCK)
				
				INNER JOIN #LicenseeCust c WITH (NOLOCK) 
				ON b.custid 		= c.custid
				AND b.recommend 	= c.recommend
				
			WHERE Winlostdate = @Date
				AND StatusId IN (111, 112, 113)
			GROUP BY Winlostdate
			
		END
		ELSE
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
			SELECT 
				Winlostdate
				,11 AS ProductID
				,SUM(Stake) AS Turnover
				,0 AS Outstanding
				,SUM(Winlost) AS Winloss
				,0 AS PlayerComm
				,COUNT(1) AS BetCount
				,SUM(CASE WHEN StatusID <> 111 THEN Stake ELSE 0 END) AS TurnoverNoDraw
				,SUM(CASE WHEN StatusID <> 111 THEN 1 ELSE 0 END) AS BetCountNoDraw

			FROM DBARC.bodb_archive.dbo.bettrans_AGCasino_bk b WITH(NOLOCK)
				
				INNER JOIN #LicenseeCust c WITH (NOLOCK) 
				ON b.custid 		= c.custid
				AND b.recommend 	= c.recommend
				
			WHERE Winlostdate = @Date
				AND StatusId IN (111, 112, 113)

			GROUP BY Winlostdate
		END
	END
	
	--Gold-Delux
	IF (EXISTS (SELECT 1 FROM #ProductBettype WHERE ProductId = 12)) 
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
		SELECT 
			Winlostdate
			,12 AS ProductID
			,SUM(Stake) AS Turnover
			,0 AS Outstanding
			,SUM(Winlost) AS Winloss
			,0 AS PlayerComm
			,COUNT(1) AS BetCount
			,SUM(CASE WHEN StatusID <> 111 THEN Stake ELSE 0 END) AS TurnoverNoDraw
			,SUM(CASE WHEN StatusID <> 111 THEN 1 ELSE 0 END) AS BetCountNoDraw

		FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_GoldDeluxe b WITH(NOLOCK)
			
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
			ON b.custid 		= c.custid
			AND b.recommend 	= c.recommend
			
		WHERE Winlostdate = @Date
			AND StatusId IN (111, 112, 113)

		GROUP BY Winlostdate
	END
	
	--Macau - Voidbridge
	IF (EXISTS (SELECT 1 FROM #ProductBettype WHERE ProductId = 14)) 
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
		SELECT 
			Winlostdate
			,14 AS ProductID
			,SUM(ABS(ISNULL([StakeAmount], 0))) AS Turnover
			,0 AS Outstanding
			,SUM(ISNULL(b.[WinAmount],0) - ABS(ISNULL(b.[StakeAmount], 0)))  AS Winloss
			,0 AS PlayerComm
			,COUNT(1) AS BetCount
			,SUM(CASE WHEN Status <> 'Draw' THEN ABS(ISNULL([StakeAmount], 0)) ELSE 0 END) AS TurnoverNoDraw
			,SUM(CASE WHEN Status <> 'Draw' THEN 1 ELSE 0 END) AS BetCountNoDraw

		FROM DBLIC.bodb_3rdProduct.dbo.BetTrans_VoidBridge b WITH(NOLOCK)
			
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
			ON b.custid 		= c.custid
			AND b.recommend 	= c.recommend
			
		WHERE Winlostdate = @Date
			AND [Status] IN ('Win','Lose')
			
		GROUP BY Winlostdate
	END
	
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
		SELECT TOP 1 1 AS ProductID 
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
	DROP TABLE #TempTrans
	
	DROP TABLE #ProductBettype
	
	DROP TABLE #rptData

	DROP TABLE #tmpBettrans

	DROP TABLE #tmpFunding

	DROP TABLE #LicenseeCust

	DROP TABLE #ProductSporttype

	DROP TABLE #CashOutMember
END
GO