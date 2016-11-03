 
CREATE PROCEDURE [dbo].[Aff_PlayersWinlostByProductSel] 
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
	- 20160119@Bobby: #51099 - Get member data by sporttype after movebetday
	- 20161022@Jim:move table to bodb_licenseereport [RedmineID :#60449]
	
  
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
	
	CREATE TABLE #ProductSporttype (
		ProductId 		TINYINT
		, Sporttype 	SMALLINT
	)
	
	DECLARE @ProductFilter TABLE (ProductId TINYINT)
	INSERT INTO @ProductFilter ( ProductId )
	SELECT CAST(val AS TINYINT) AS ProductId 
	FROM [dbo].[strSplit_Key](@ProductIDs, ',')
	
	-- insert product & bettype mapping
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
	
	-- insert product & Sporttype mapping
	INSERT INTO #ProductSporttype (
		ProductId
		, Sporttype
	)
	SELECT DISTINCT p.ProductId
		, bt.Sporttype
	FROM dbo.SportBettypeMatrix bt WITH(NOLOCK)
		INNER JOIN @ProductFilter p
		ON bt.ProductId = p.ProductId
	WHERE bt.IsTest 	= 0
		AND bt.Enabled 	= 1
	
	DECLARE @CutDate DATETIME
		,@MaxDate DATETIME
		
	SELECT @CutDate = min(winlostdate)
		,@MaxDate = MAX(Winlostdate)
	FROM bodb_licenseeReport.dbo.rptLicWinloss2 WITH (NOLOCK)

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
	FROM @Xml.nodes('//root/trans') AS [Table]([Column])

	INSERT INTO #LicenseeCust
	SELECT c.CustID
		,c.Currency
		,t.UserName
		,c.srecommend
		,c.mrecommend
		,c.recommend
	FROM bodb02.dbo.customer c WITH (NOLOCK)
		INNER JOIN #TempTrans AS t ON @Prefix + t.username = c.username2
		--INNER JOIN #TempTrans AS t ON t.username = c.username
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
		FROM bodb_licenseeReport.dbo.rptLicWinloss2 b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
			ON b.custid 			= c.custid
				AND b.recommend 	= c.recommend
				AND b.srecommend 	= c.srecommend
			INNER JOIN #ProductSporttype bt
			----ON b.Sporttype			= bt.Sporttype
			ON CASE WHEN b.Sporttype = 0 THEN 1 -- Sportbook
					ELSE b.Sporttype 
				END = bt.Sporttype
			
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
		FROM bodb_licenseeReport.dbo.rptLicWinloss_old b WITH (NOLOCK)
			INNER JOIN #LicenseeCust c WITH (NOLOCK) 
				ON b.custid 		= c.custid
				AND b.recommend 	= c.recommend
				AND b.srecommend 	= c.srecommend
			INNER JOIN #ProductSporttype bt
			--ON b.Sporttype			= bt.Sporttype
			ON CASE WHEN b.Sporttype = 0 THEN 1 -- Sportbook
					ELSE b.Sporttype 
				END = bt.Sporttype
			
		WHERE b.winlostdate = @Date
			AND b.BetCount 	> 0
			AND b.roleid 	= 1
			AND StatusID NOT IN (101, 102, 103, 121, 1)
			
		GROUP BY b.winlostdate
			,b.CustID
			,c.username
			,bt.ProductId
	END
	
	--AG-Casino
	IF (EXISTS (SELECT 1 FROM #ProductBettype WHERE ProductId = 11) )
	BEGIN
		DECLARE @AGCS_BackupDay 	DATE
		
		SELECT @AGCS_BackupDay 		= ISNULL(MIN(Winlostdate),'') 
		FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_AGCasino WITH(NOLOCK)
		
		IF (@Date >= @AGCS_BackupDay)-- Get data in bettrans_AGCasino table
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
			SELECT 
				@Date AS Winlostdate
				,c.CustID
				,c.Username
				,11 AS ProductID
				,SUM(Stake) AS Turnover
				,0 AS Outstanding
				,SUM(Winlost - actual_stake) AS Winloss
				,SUM(CASE 
							WHEN statusID = 111 THEN stake
							ELSE 0
							END) AS DrawGame
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
			GROUP BY c.CustID
					,c.Username
			
		END
		ELSE
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
			SELECT 
				@Date AS Winlostdate
				,c.CustID
				,c.Username
				,11 AS ProductID
				,SUM(Stake) AS Turnover
				,0 AS Outstanding
				,SUM(Winlost - actual_stake) AS Winloss
				,SUM(CASE 
							WHEN statusID = 111 THEN stake
							ELSE 0
							END) AS DrawGame
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

			GROUP BY c.CustID
					,c.Username
		END
	END
	
	--Gold-Delux
	IF (EXISTS (SELECT 1 FROM #ProductBettype WHERE ProductId = 12)) 
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
		SELECT 
			@Date AS Winlostdate
			,c.CustID
			,c.Username
			,12 AS ProductID
			,SUM(Stake) AS Turnover
			,0 AS Outstanding
			,SUM(Winlost - Stake) AS Winloss
			,SUM(CASE 
						WHEN statusID = 111 THEN stake
						ELSE 0
						END) AS DrawGame
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

		GROUP BY c.CustID
				,c.Username
	END
	
	--Macau - Voidbridge
	IF (EXISTS (SELECT 1 FROM #ProductBettype WHERE ProductId = 14)) 
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
		SELECT 
			@Date AS Winlostdate
			,c.CustID
			,c.Username
			,14 AS ProductID
			,SUM(ABS(ISNULL([StakeAmount], 0))) AS Turnover
			,0 AS Outstanding
			,SUM(ISNULL(b.[WinAmount],0) - ABS(ISNULL(b.[StakeAmount], 0)))  AS Winloss
			,0 AS DrawGame
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
			
		GROUP BY c.CustID
			,c.Username
	END
	
	--Final rersult OUTPUT
	SELECT *
	FROM #tmpRpt b WITH (NOLOCK)

	DROP TABLE #TempTrans	
	DROP TABLE #ProductBettype
	DROP TABLE #ProductSporttype
	DROP TABLE #tmpRpt
	DROP TABLE #LicenseeCust
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [bodbAdminNet]
GO 
