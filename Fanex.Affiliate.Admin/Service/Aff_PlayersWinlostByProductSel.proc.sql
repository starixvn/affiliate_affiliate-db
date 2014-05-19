USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Aff_PlayersWinlostByProductSel]    Script Date: 05/09/2014 00:20:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Aff_PlayersWinlostByProductSel] 
	@Xml XML
	,@Prefix VARCHAR(100)
	,@Date SMALLDATETIME
AS
/*  
Created: 20130111@Peter  
Task :   
DB: DB052/DB054.bodb02  
  
  
Revisions:  
          - 20131028@Peter : Add more DB columns https://redmine.nexcel.vn/issues/5280
		  - 20140416@Dan: include Keno
		  - 20140502@Dan: optimize perfomance
		  - 20140502@Dan: support Playtech casino
  
Param's Explanation:  
  
   
*/
BEGIN
	SET NOCOUNT ON

	SELECT @Date = dateadd(dd, datediff(dd, 0, @DATE), 0)

	--create table #LicenseeCust(custID INT PRIMARY KEY,currency int,username varchar(100), srecommend int, mrecommend int, recommend int)  
	CREATE TABLE #LicenseeCust (
		custID INT
		,currency INT
		,username VARCHAR(100)
		,srecommend INT
		,mrecommend INT
		,recommend INT
		)

	DECLARE @CutDate DATETIME
		,@MaxDate DATETIME

	SELECT @CutDate = min(winlostdate)
		,@MaxDate = MAX(Winlostdate)
	FROM bodb_licensee.dbo.rptLicWinloss2 WITH (NOLOCK)

	CREATE TABLE #tmpRpt (
		Winlostdate SMALLDATETIME
		,CustID INT
		,Username NVARCHAR(50)
		,ProductID INT
		,Turnover MONEY
		,Outstanding MONEY
		,Winloss MONEY
		,DrawGame MONEY
		,PlayerComm MONEY
		,BetCount INT
		,TurnoverNoDraw MONEY
		,BetCountNoDraw INT
		)

	DECLARE @TempTrans TABLE
		--CREATE TABLE #TempTrans
		(UserName VARCHAR(30))

	INSERT INTO @TempTrans (UserName) --Convert xml to table
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS UserName
	FROM @Xml.nodes('/root/trans') AS [Table]([Column])

	--print @sqlCommand
	INSERT INTO #LicenseeCust
	SELECT c.CustID
		,c.Currency
		,t.UserName
		,c.srecommend
		,c.mrecommend
		,c.recommend
	FROM bodb02.dbo.customer c WITH (NOLOCK)
		INNER JOIN @TempTrans AS t ON @Prefix + t.username = c.username2
	WHERE c.roleid = 1

	-- select * from #LicenseeCust  (nolock)
	IF @Date > @MaxDate
	BEGIN
		INSERT INTO #tmpRpt (
			Winlostdate
			,CustID
			,Username
			,ProductID
			,Turnover
			,Outstanding
			,Winloss
			,DrawGame
			,PlayerComm
			,BetCount
			,TurnoverNoDraw
			,BetCountNoDraw
			)
		SELECT @Date
			,b.custid
			,c.username
			,CASE 
				WHEN bettype IN (71, 72) THEN 251 --casino
				WHEN bettype = 1000 THEN 253 --games
				WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN 151 -- Horse Racing
				WHEN bettype BETWEEN 81
						AND 120 THEN 161 -- Number Game 
				WHEN bettype BETWEEN 1101
						AND 1199 THEN 162 -- Live Casino
				WHEN bettype BETWEEN 1201
						AND 1299 THEN 180 --Virtual Sport	
				WHEN bettype BETWEEN 51
						AND 69 THEN 201 -- Financial	
				WHEN bettype BETWEEN 1501
						AND 1599 THEN 202 -- Keno  
				WHEN b.bettype < 31
					OR (
						b.bettype BETWEEN 121
							AND 999
						) THEN 0 -- sportsbook
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
					WHEN statusID = 111 THEN stake
					ELSE 0
					END)
			,-- Draw game TO
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
		FROM bettrans b WITH (NOLOCK, INDEX (IX_recommend_transid))
			INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid = c.custid
			AND b.recommend = c.recommend
		WHERE winlostdate = @date
			AND bettype < 19999
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'      
		GROUP BY b.custid
			,c.username
			,CASE 
				WHEN bettype IN (71, 72) THEN 251 --casino
				WHEN bettype = 1000 THEN 253 --games
				WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN 151 -- Horse Racing
				WHEN bettype BETWEEN 81
						AND 120 THEN 161 -- Number Game 
				WHEN bettype BETWEEN 1101
						AND 1199 THEN 162 -- Live Casino
				WHEN bettype BETWEEN 1201
						AND 1299 THEN 180 --Virtual Sport	
				WHEN bettype BETWEEN 51
						AND 69 THEN 201 -- Financial
				WHEN bettype BETWEEN 1501
						AND 1599 THEN 202 -- Keno  
				WHEN b.bettype < 31
					OR (
						b.bettype BETWEEN 121
							AND 999
						) THEN 0 -- sportsbook 
				ELSE - 1
				END
	END
	ELSE IF @Date >= @CutDate
	BEGIN
		INSERT INTO #tmpRpt (
			Winlostdate
			,CustID
			,Username
			,ProductID
			,Turnover
			,Outstanding
			,Winloss
			,DrawGame
			,PlayerComm
			,BetCount
			,TurnoverNoDraw
			,BetCountNoDraw
			)
		SELECT b.winlostdate
			,b.CustID
			,c.username
			,b.Sporttype
			,sum(b.turnover)
			,0 AS Outstanding
			,sum(b.winlost)
			,sum(CASE 
					WHEN statusID = 111 THEN turnover
					ELSE 0
					END)
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
			INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid = c.custid
			AND b.recommend = c.recommend
			AND b.srecommend = c.srecommend
		WHERE b.winlostdate = @Date
			AND b.BetCount > 0
			AND b.roleid = 1
			AND b.sporttype IN (0, 151, 161, 162, 180, 201, 251, 253, 202)
			-- and b.isBA=0
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,b.CustID
			,c.username
			,b.Sporttype
	END
	ELSE IF @Date < @CutDate
	BEGIN
		INSERT INTO #tmpRpt (
			Winlostdate
			,CustID
			,Username
			,ProductID
			,Turnover
			,Outstanding
			,Winloss
			,DrawGame
			,PlayerComm
			,BetCount
			,TurnoverNoDraw
			,BetCountNoDraw
			)
		SELECT b.winlostdate
			,b.CustID
			,c.username
			,b.Sporttype
			,SUM(b.turnover)
			,0 AS Outstanding
			,SUM(b.winlost)
			,SUM(CASE 
					WHEN statusID = 111 THEN turnover
					ELSE 0
					END)
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
			INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid = c.custid
			AND b.recommend = c.recommend
			AND b.srecommend = c.srecommend
		WHERE b.winlostdate = @Date
			AND b.BetCount > 0
			AND b.roleid = 1
			AND b.sporttype IN (0, 151, 161, 162, 180, 201, 251, 253, 202)
			-- and b.isBA=0
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,b.CustID
			,c.username
			,b.Sporttype
	END

	INSERT INTO #tmpRpt (
		Winlostdate
		,CustID
		,Username
		,ProductID
		,Turnover
		,Outstanding
		,Winloss
		,DrawGame
		,PlayerComm
		,BetCount
		,TurnoverNoDraw
		,BetCountNoDraw
		)
	SELECT b.winlostdate
		,b.CustID
		,c.username
		,b.Sporttype
		,b.turnover
		,Outstanding
		,b.winlost
		,drawTO AS DrawGame
		,b.playercomm
		,b.BetCount
		,(b.turnover - b.drawTO) AS TurnoverNoDraw
		,(b.BetCount - drawBetCount) AS BetCountNoDraw
	FROM DBRPT.bodb_Report.dbo.rptDepWinlost_PlaytechCS b WITH (NOLOCK)
		INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid = c.custid
	WHERE b.winlostdate = @Date
		AND sporttype = 254
		AND b.BetCount > 0

	SELECT *
	FROM #tmpRpt b WITH (NOLOCK)

	DROP TABLE #tmpRpt

	DROP TABLE #LicenseeCust
END
GO

GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnteam] AS [dbo]
