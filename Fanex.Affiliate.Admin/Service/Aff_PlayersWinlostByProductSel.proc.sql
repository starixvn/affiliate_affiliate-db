USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Aff_PlayersWinlostByProductSel]    Script Date: 05/09/2014 00:20:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Aff_PlayersWinlostByProductSel] 
	@Xml 			XML
	,@Prefix 		VARCHAR(100)
	,@Date 			SMALLDATETIME
	,@ProductIDs 	VARCHAR(100) 	= NULL
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
	- 20140610@Bobby: Add ProgressiveShare & ProgressiveWin columns
	- 20141016@Bobby: Add bettype Tenis's Sporting Solution and IBC
	- 20151022@Bobby: Get member data by Product list
	
  
Param's Explanation:  
	- @Xml: List member's username is under affiliate user
		+ Example: '<root>
		<trans username="train1991"></trans>
		<trans_N username="XXX"></trans></root>
	- @Prefix: Is the Licensee Name as default plus ($) sign
	- @Date: Date only
 
*/
BEGIN
	SET NOCOUNT ON

	SELECT @Date = dateadd(dd, datediff(dd, 0, @DATE), 0)

	--create table #LicenseeCust(custID INT PRIMARY KEY,currency int,username varchar(100), srecommend int, mrecommend int, recommend int)  
	CREATE TABLE #LicenseeCust (
		custID 			INT
		,currency 		INT
		,username 		VARCHAR(100)
		,srecommend 	INT
		,mrecommend 	INT
		,recommend 		INT
	)
	-- Do filtering product 
	CREATE TABLE #ProductBettype (
		ProductId 		TINYINT
		, Bettype		SMALLINT
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
		, bt.Bettype
	FROM dbo.SportBettypeMatrix bt WITH(NOLOCK)
		INNER JOIN @ProductFilter p
		ON bt.ProductId = p.ProductId
	WHERE bt.IsTest 	= 0
		AND bt.Enabled 	= 1
	
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
		,ProgressiveShare MONEY DEFAULT(0)
		,ProgressiveWin MONEY DEFAULT(0)
	)

	CREATE TABLE #TempTrans(UserName VARCHAR(30))

	INSERT INTO #TempTrans (UserName) --Convert xml to table
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS UserName
	FROM @Xml.nodes('/root/trans') AS [Table]([Column])

	INSERT INTO #LicenseeCust
	SELECT c.CustID
		,c.Currency
		,t.UserName
		,c.srecommend
		,c.mrecommend
		,c.recommend
	FROM bodb02.dbo.customer c WITH (NOLOCK)
		INNER JOIN #TempTrans AS t ON @Prefix + t.username = c.username2
	WHERE c.roleid = 1

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
			,bt.ProductId
			,-- undefined productid
			SUM(b.stake) AS Turnover
			,--Turnover  
			SUM(CASE 
					WHEN ruben = 0 THEN actual_stake
					ELSE 0
					END) AS Outstanding  
			,--Outstanding  
			SUM(CASE 
					WHEN ruben = 1 THEN b.winlost - b.actual_stake
					ELSE 0
					END) AS WinLoss
			,--Winloss      
			SUM(CASE 
					WHEN statusID = 111 THEN stake
					ELSE 0
					END) AS DrawGame
			,-- Draw game TO
			SUM(CASE 
					WHEN ruben = 1 THEN b.playercomm
					ELSE 0
					END) AS PlayerComm
			,--Playercomm      
			COUNT(1) AS BetCount
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
					END) AS TurnoverNoDraw
			,-- Turnover No Draw
			SUM(CASE 
					WHEN b.statusID = 111 THEN 0
					ELSE 1
					END) AS BetCountNoDraw
					
		FROM bettrans b WITH (NOLOCK, INDEX (IX_recommend_transid))
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
			ON b.custid 			= c.custid
			AND b.recommend 	= c.recommend
			INNER JOIN #ProductBettype bt
			ON b.bettype 			= bt.bettype
			
		WHERE b.winlostdate = @date
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)--status not in ('VOID', 'REJECT', 'REFUND','DONE', 'waiting' )
			
		GROUP BY b.custid
			,c.username
			,bt.ProductId
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
			,bt.ProductId
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
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
			ON b.custid 			= c.custid
				AND b.recommend 	= c.recommend
				AND b.srecommend 	= c.srecommend
			INNER JOIN #ProductBettype bt
			ON b.bettype 			= bt.bettype
			
		WHERE b.winlostdate = @Date
			AND b.BetCount 	> 0
			AND b.roleid 	= 1
			AND StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.winlostdate
			,b.CustID
			,c.username
			,bt.ProductId
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
			,bt.ProductId
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
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
				ON b.custid 		= c.custid
				AND b.recommend 	= c.recommend
				AND b.srecommend 	= c.srecommend
			INNER JOIN #ProductBettype bt
			ON b.bettype 			= bt.bettype
		WHERE b.winlostdate = @Date
			AND b.BetCount 	> 0
			AND b.roleid 	= 1
			AND StatusID NOT IN (101, 102, 103, 121, 1)
			
		GROUP BY b.winlostdate
			,b.CustID
			,c.username
			,bt.ProductId
	END
	
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
