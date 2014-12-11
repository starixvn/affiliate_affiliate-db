USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_BetList_SelWinLossByDate]    Script Date: 10/16/2014 10:36:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_BetList_SelWinLossByDate]
	@CustId 					INT
	,@FromDate 					SMALLDATETIME
	,@ToDate 					SMALLDATETIME
	,@MoveBetsDay 				SMALLDATETIME
	,@Language 					VARCHAR(2) 		= 'E'
	,@ShowSB 					BIT 			= 1
	,@ShowCasino 				BIT 			= 0
	,@ShowRB 					BIT 			= 0
	,@ShowNG 					BIT 			= 0
	,@ShowLiveCasino 			BIT 			= 0
	,@ShowVS 					BIT 			= 0
	,@ShowProgressiveBonus 		BIT 			= 0
	,@ShowKeno 					BIT 			= 0
	,@Error						INT 			= 0 	OUTPUT
	,@ErrorMsg					NVARCHAR(500) 	= '' 	OUTPUT
	,@Duration					INT 			= 0 	OUTPUT
AS
/*
Created: 20141016@Bobby.Nguyen
Task: Implement Affilite member betlist
DB:	DBEXT.bodb02
Original: DBEXT.bodb02.dbo.[Age_BetList_SelWinLossByDate_Mem]

Revisions:           
	20141016@Bobby.Nguyen: Initial affiliate member betlist
	
Param's Explanation: 
	- @CustID: 		Customer/Player ID
	- @FromDate: 	Date only
	- @ToDate: 		Date only
	- @Language: 	translate to which language
	- @MoveBetsDay: Date only that is a move bet day
	- @ShowSB: 		Show sportbooks
	- @ShowCasino: 	Show casino
	- @ShowRB:		Show racing,
	- @ShowNG:		Show Number Game
	- @ShowKeno:	Show Keno
	- @ShowVS:		Show Virtual Sports
	- @ShowLiveCasino: 			Show Live Casino
	- @ShowProgressiveBonus: 	Show Playtech Casino
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @UserName 	NVARCHAR(20)
		, @Recommend 	INT
		, @_custid 		INT
		, @startRun 	DATETIME
		
	SELECT @_CustID = @CustID
		,@startRun 	= GETDATE()
	
	SELECT TOP(1) @UserName = UserName
		, @Recommend		= Recommend 
	FROM dbo.custinfo WITH(NOLOCK) 
	WHERE CustID = @_CustID

	IF(@UserName IS NULL)
	BEGIN
		SELECT @Error		= 101
			,@ErrorMsg		= CASE 
									WHEN @Language = 'EN' THEN 'There is not exists member.' 
									ELSE '' 
								END
		RETURN
	END
	
	DECLARE @BetListByDateMem TABLE(
		Sporttype SMALLINT,
		Username NVARCHAR(30), 
		TransID BIGINT,
		BetID BIGINT,
		Bettype SMALLINT,
		hdp1 SMALLMONEY, 
		hdp2 SMALLMONEY, 
		OddsType TINYINT,
		Odds SMALLMONEY, 
		modds SMALLMONEY,
		Stake MONEY, 
		actual_stake MONEY,
		Betteam NVARCHAR(20),
		Status NVARCHAR(10),
		RefNO BIGINT,	
		Transdate DATETIME,
		Winlostdate DATETIME,
		
		Winlost MONEY,
		awinlost MONEY,
		mwinlost MONEY,
		swinlost MONEY,
		
		PlayerComm MONEY,
		comm MONEY,
		acomm MONEY,
		scomm MONEY,
		
		
		
		APositiontaking SMALLMONEY,
		MPositiontaking SMALLMONEY,
		SPositiontaking SMALLMONEY,
		
		Adiscount SMALLMONEY,
		Mdiscount SMALLMONEY,
		Sdiscount SMALLMONEY,
		
		Liveindicator BIT,
		Livehomescore SMALLINT,
		Liveawayscore SMALLINT,
		IP NVARCHAR(15),
		LeagueID INT,
		MatchID INT,
		MatchCode NVARCHAR(50),--VinhTrinh Add for Horseracing
		Race NVARCHAR(20),--VinhTrinh Add for Horseracing
		HomeID INT,
		AwayID INT, 	
		Betstatus NVARCHAR(50),
		isNeutral BIT,
		custid int,
		showtime NVARCHAR(50), -- table - shoe - hand of Live Casino
		BetCheck NVARCHAR(50),
		comstatus NVARCHAR(20)
	)
	
	DECLARE @BettransDetail TABLE (  
		 refno				BIGINT,  
		 odds				SMALLMONEY,  
		 stake				MONEY,
		 status				NVARCHAR(10),  
		 apositiontaking	SMALLMONEY,  
		 mpositiontaking	SMALLMONEY,  
		 spositiontaking	SMALLMONEY,
		 bettype			SMALLINT,
		 Betteam			NVARCHAR (10)
	 )   
	
	-- select from bettrans
	IF @Todate > @MoveBetsDay
	BEGIN
		--Sport Book
		IF @ShowSB = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					m.Sporttype, 
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2,
					b.OddsType, 
					b.odds, 
					b.modds,
					b.Stake, 
					b.actual_stake,
					b.betteam, 
					b.status AS Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,			
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					b.Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					m.LeagueID,
					m.MatchID,	
					m.MatchCode,
					'' AS Race,	
					m.HomeID,
					m.AwayID, 		
					m.Betstatus,
					ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
					b.custid,
					isnull(m.showtime,'') as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)		
					INNER JOIN dbo.MATCH AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND --to improve performance
					b.custid=@_CustID AND
					b.bettype < 19001 AND
					b.bettype NOT IN (51,52,53,54,55,56,61,62,63,64,65,66,10,31,32,33,41,42,43) AND --20120626@Elodie: exclude outright, HR from sportbook
					b.bettype NOT BETWEEN 81 AND 120 AND 
					b.bettype NOT BETWEEN 1101 AND 1199 AND 
					b.bettype NOT BETWEEN 1201 AND 1299 AND 
					b.bettype NOT BETWEEN 1501 AND 1599 -- exclude Keno
					--b.status not in ('running','waiting') 
					AND b.statusID IN (111,112,113) --DRAW,WON,LOSE

			-- Outright
			INSERT INTO @BetListByDateMem
				SELECT
					l.sporttype, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					0 AS hdp1, 
					0 AS hdp2, 
					0 AS OddsType, 
					b.Odds, 
					b.modds,
					b.Stake, 
					b.actual_stake,
					'' AS Betteam, --Betteam
					b.Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,			
					b.MPositiontaking,			
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0 AS LiveIndicator , 
					b.LiveHomescore, 
					b.LiveAwayscore,
					b.IP AS IP,
					m.LeagueID,
					m.OrId,--0, --MatchID	
					m.MatchCode,
					m.GroupMatch,--Race
					m.TeamID, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus				
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)		
					INNER JOIN dbo.Outright AS m WITH (NOLOCK) ON b.matchid=m.orid
					INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype = 10 AND
					--b.status not in ('running','waiting') and
					b.statusID NOT IN (111,112,113) 
					

			-- Mix Parlay		
			INSERT INTO @BetListByDateMem
				SELECT
					0, --Sporttype
					@Username, 
					CASE WHEN ISNULL(b.betid,0) = 0 THEN b.TransID ELSE b.betid END AS transid,
					ISNULL(b.BetID,0),
					b.bettype,
					b.hdp1, 
					b.hdp2, 
					0 AS OddsType, 
					b.Odds, 
					b.modds,
					b.Stake,
					b.actual_stake, 
					b.Betteam,
					b.Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					b.Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					0, --LeagueID
					0, --MatchID	
					'',--MatchCode
					'',--Race
					0, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)	
					--left join dbo.Match_Remark as mr with (nolock) on mr.matchid = b.matchid
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype IN (9, 29) AND
					--b.matchid = 0 and
					b.matchid IN (9, 29) AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END
		
		-- Horse Racing
		IF @ShowRB = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					l.sporttype, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2,
					0 AS OddsType, 
					b.Odds, 
					b.modds,
					b.Stake, 
					b.actual_stake,
					'' AS Betteam, --Betteam
					b.Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,			
					b.MPositiontaking,			
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0 AS LiveIndicator , 
					b.LiveHomescore, 
					b.LiveAwayscore,
					b.IP AS IP,
					m.LeagueID,
					m.OrId,--0, --MatchID	
					m.MatchCode,
					m.GroupMatch,--Race
					m.TeamID, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus				
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)		
					INNER JOIN dbo.Outright AS m WITH (NOLOCK) ON b.matchid=m.orid
					INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype IN (31, 32, 33,41,42,43) AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END
					
		-- Casino
		IF @ShowCasino = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					251, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.bettype,
					0, 
					0,
					0 AS OddsType,  
					0 as Odds, 
					0 as modds,
					b.Stake, 
					b.actual_stake,
					'', --Betteam
					b.Status,
					b.Refno,				
					b.Transdate,	
					b.winlostdate,						
					b.winlost-actual_stake,
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0,
					0,
					0,
					b.IP AS IP,
					0, --LeagueID
					0, --MatchID	
					'',--MatchCode
					'',--Race
					0, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)	
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype = 71 AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END
		
		--Number Game
		IF @ShowNG = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				0 AS hdp2,
				b.OddsType,
				b.odds, 
				b.modds,
				b.Stake, 
				b.actual_stake,
				b.Betteam,
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				b.PlayerComm,
				(b.comm - b.playercomm) AS comm,
				(b.acomm - b.comm) AS acomm ,
				(b.scomm - b.acomm) AS scomm,
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				
				b.discount,
				b.adiscount,
				b.sdiscount,
				
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				CONVERT(BIT,0) AS IsNeutral	,
				b.custid,
				'' as showtime,
				'' as betcheck ,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus		
			FROM
				dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)		
				INNER JOIN dbo.MATCH AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
			WHERE
				b.winlostdate BETWEEN @fromdate AND @todate AND
				b.recommend = @Recommend AND --to improve performance
				b.custid=@_CustID AND
				b.bettype BETWEEN 81 AND 120 AND
				b.statusID  IN (111,112,113)					
		END

		--Live Casino
		IF @ShowLiveCasino = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2,
				b.OddsType,
				b.odds, 
				b.modds,
				b.Stake, 
				b.actual_stake,
				b.Betteam,
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				b.PlayerComm,
				(b.comm - b.playercomm) AS comm,
				(b.acomm - b.comm) AS acomm ,
				(b.scomm - b.acomm) AS scomm,
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				
				b.discount,
				b.adiscount,
				b.sdiscount,
				
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				CONVERT(BIT,0) AS IsNeutral	,
				b.custid,
				ISNULL(m.showtime, '') as showtime,
				'' as betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans AS b WITH (NOLOCK)		
				INNER JOIN dbo.MATCH AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
			WHERE
				b.winlostdate BETWEEN @fromdate AND @todate AND
				b.recommend = @Recommend AND  
				b.custid=@_CustID AND
				b.bettype BETWEEN 1101 AND 1199 AND
				b.statusID  IN (111,112,113)					
		END
		
		--Virtual Sports
		IF @ShowVS = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					m.Sporttype, 
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2,
					b.OddsType, 
					b.odds, 
					b.modds,
					b.Stake, 
					b.actual_stake,
					b.betteam, 
					b.status AS Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,			
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					b.Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					m.LeagueID,
					m.MatchID,	
					m.MatchCode,
					'' AS Race,	
					m.HomeID,
					m.AwayID, 		
					m.Betstatus,
					ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
					b.custid,
					isnull(m.showtime,'') as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)		
					INNER JOIN dbo.MATCH AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND --to improve performance
					b.custid=@_CustID AND
					b.bettype BETWEEN 1201 AND 1299 AND
					b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) AND
					--b.status not in ('running','waiting') 
					b.statusID  IN (111,112,113)
				
				INSERT INTO @BetListByDateMem
				SELECT
					r.Sporttype, 
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2,
					0 as OddsType, 
					b.odds, 
					b.modds,
					b.Stake, 
					b.actual_stake,
					'' as betteam, 
					b.status AS Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,			
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0 as Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					r.LeagueID,
					b.MatchID,	
					o.RacerNum as MatchCode,
					b.oddsid as Race,	
					o.RacerID as homeID,
					0 as awayID,		
					'' Betstatus,
					CONVERT(BIT,0) as IsNeutral,
					b.custid,
					r.EventTime as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)		
					INNER JOIN VSOutright o with (NOLOCK) ON b.oddsid = o.Orid
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND --to improve performance
					b.custid=@_CustID AND
					b.bettype IN (/*1231,1232,1233,1237,1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) AND
					b.statusID  IN (111,112,113)
		END 
		
		-- Playtech Casino - Progressive bonus
		IF @ShowProgressiveBonus = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					251, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.bettype,
					0, 
					0,
					0 AS OddsType,  
					0 as Odds, 
					0 as modds,
					b.Stake, 
					b.actual_stake,
					'', --Betteam
					b.Status,
					b.Refno,				
					b.Transdate,	
					b.winlostdate,						
					b.winlost-actual_stake,
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0,
					0,
					0,
					b.IP AS IP,
					0, --LeagueID
					0, --MatchID	
					'',--MatchCode
					'',--Race
					0, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans AS b WITH (NOLOCK, index=IX_custid_matchid_bettype)	
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype = 72 AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)				
		END	

		--Keno
		IF @ShowKeno = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
			SELECT
				202 AS Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID, 0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2,
				b.OddsType,
				b.odds, 
				b.modds,
				b.Stake, 
				b.actual_stake,
				fnc.ChoiceId AS Betteam,
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				b.PlayerComm,
				(b.comm - b.playercomm) AS comm,
				(b.acomm - b.comm) AS acomm ,
				(b.scomm - b.acomm) AS scomm,
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				
				b.discount,
				b.adiscount,
				b.sdiscount,
				
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0 LeagueID,
				fnc.GameId AS MatchID,	
				'' AS MatchCode,
				'' AS Race,	
				0 AS HomeID,
				0 AS AwayID, 		
				0 AS Betstatus,
				CONVERT(BIT, 0) AS IsNeutral,
				b.custid,
				'' AS showtime,
				'' AS betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans AS b WITH (NOLOCK)
				CROSS APPLY dbo.f_ParseTransDesc(b.transdesc, b.bettype) AS fnc
			WHERE
				b.winlostdate BETWEEN @fromdate AND @todate AND
				b.recommend = @Recommend AND  
				b.custid = @_CustID AND
				b.bettype BETWEEN 1501 AND 1599 AND
				b.statusID  IN (111,112,113)					
		END

	END

	-- select from bettrans14
	IF @Fromdate <= @MoveBetsDay
	BEGIN
		--Sport Book
		IF @ShowSB = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
				SELECT
					m.Sporttype, 
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2, 
					b.OddsType, 
					b.odds,
					b.modds,
					b.Stake, 
					b.actual_stake,
					b.betteam, 
					b.status AS Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					b.Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					m.LeagueID,
					m.MatchID,	
					m.MatchCode,
					'' AS Race,	--Race
					m.HomeID,
					m.AwayID, 		
					m.Betstatus,
					ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
					INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid 					
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype < 19001
					AND b.bettype NOT IN (51,52,53,54,55,56,61,62,63,64,65,66,10,31,32,33,41,42,43) --20120626@Elodie: exclude outright, HR from sportbook
					AND b.bettype NOT BETWEEN 81 AND 120  
					AND b.bettype NOT BETWEEN 1101 AND 1199 
					AND b.bettype NOT BETWEEN 1201 AND 1299 
					AND b.bettype NOT BETWEEN 1501 AND 1599 -- exclude Keno
					--b.status not in ('running','waiting') and
					AND b.statusID  IN (111,112,113)
					

			INSERT INTO @BetListByDateMem
				SELECT
					0, --Sporttype
					@Username, 
					CASE WHEN ISNULL(b.betID,0) = 0 THEN b.TransID ELSE b.betid END AS transid,
					ISNULL(b.BetID,0),
					b.bettype,
					b.hdp1, 
					b.hdp2, 
					0 AS OddsType, 
					b.Odds,
					b.modds, 
					b.Stake, 
					b.actual_stake,
					b.Betteam,
					b.Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					b.Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					0, --LeagueID
					0, --MatchID
					'',--MatchCode
					'',--Race	
					0, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS isNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)	
					--LEFT JOIN dbo.Match_Remark as mr with (nolock) on b.matchid = mr.matchid				
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype IN(9, 29) AND
					--b.matchid = 0 and
					b.matchid IN(9, 29) AND --will remove 0 if the data is correct
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
				
					
			INSERT INTO @BetListByDateMem
				SELECT
					l.sporttype, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					0 AS hdp1, 
					0 AS hdp2, 
					0 AS OddsType, 
					b.Odds, 
					b.modds,
					b.Stake,
					b.actual_stake, 
					'' AS Betteam, --Betteam
					b.Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,			
					b.MPositiontaking,			
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0 AS LiveIndicator, 
					b.LiveHomescore, 
					b.LiveAwayscore,
					b.IP AS IP,
					m.LeagueID,
					m.OrId,--0, --MatchID	
					m.MatchCode,
					m.GroupMatch AS Race,--Race
					m.TeamID, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS isNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
					INNER JOIN dbo.Outright14 AS m WITH (NOLOCK) ON b.matchid=m.orid
					INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype = 10 AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END	
		
		--Horse Racing
		IF @ShowRB = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					l.sporttype, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2, 
					0 AS OddsType, 
					b.Odds, 
					b.modds,
					b.Stake,
					b.actual_stake, 
					'' AS Betteam, --Betteam
					b.Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,			
					b.MPositiontaking,			
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0 AS LiveIndicator, 
					b.LiveHomescore, 
					b.LiveAwayscore,
					b.IP AS IP,
					m.LeagueID,
					m.OrId,--0, --MatchID	
					m.MatchCode,
					m.GroupMatch AS Race,--Race
					m.TeamID, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS isNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
					INNER JOIN dbo.Outright14 AS m WITH (NOLOCK) ON b.matchid=m.orid
					INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype IN (31, 32, 33,41,42,43) AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END
				
		-- Casino
		IF @ShowCasino = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					251, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.bettype,
					0, 
					0,
					0 AS OddsType,  
					0 as Odds, 
					0 as Modds, 
					b.Stake, 
					b.actual_stake,
					'', --Betteam
					b.Status,
					b.Refno,				
					b.Transdate,	
					b.winlostdate,						
					b.winlost-actual_stake,
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0,
					0,
					0,
					b.IP AS IP,
					0, --LeagueID
					0, --MatchID	
					'',--MatchCode
					'',--Race
					0, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype = 71 AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END
		
		--Number Game
		IF @ShowNG = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				0 AS hdp2,
				b.OddsType,
				b.odds, 
				b.Modds,
				b.Stake, 
				b.actual_stake,
				b.Betteam,
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				b.PlayerComm,
				(b.comm - b.playercomm) AS comm,
				(b.acomm - b.comm) AS acomm ,
				(b.scomm - b.acomm) AS scomm,
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				
				b.discount,
				b.adiscount,
				b.sdiscount,
				
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				CONVERT(BIT,0) AS IsNeutral	,
				b.custid,
				'' showtime,
				'' as betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus		
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
				INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
			WHERE
				b.winlostdate BETWEEN @fromdate AND @todate AND
				b.recommend = @Recommend AND --to improve performance
				b.custid=@_CustID AND
				b.bettype BETWEEN 81 AND 120 AND
				b.statusID  IN (111,112,113)					
		END
			
		--Live Casino
		IF @ShowLiveCasino = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2,
				b.OddsType,
				b.odds, 
				b.Modds,
				b.Stake, 
				b.actual_stake,
				b.Betteam,
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				b.PlayerComm,
				(b.comm - b.playercomm) AS comm,
				(b.acomm - b.comm) AS acomm ,
				(b.scomm - b.acomm) AS scomm,
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				
				b.discount,
				b.adiscount,
				b.sdiscount,
				
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				CONVERT(BIT,0) AS IsNeutral	,
				b.custid, 
				isnull(m.showtime,'') as showtime,
				'' as betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
				INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
			WHERE
				b.winlostdate BETWEEN @fromdate AND @todate AND
				b.recommend = @Recommend AND --to improve performance
				b.custid=@_CustID AND
				b.bettype BETWEEN 1101 AND 1199 AND
				b.statusID  IN (111,112,113)					
		END
		
		--Virtual Sports
		IF @ShowVS = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
				SELECT
					m.Sporttype, 
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2, 
					b.OddsType, 
					b.odds,
					b.modds,
					b.Stake, 
					b.actual_stake,
					b.betteam, 
					b.status AS Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,						
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					b.Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					m.LeagueID,
					m.MatchID,	
					m.MatchCode,
					'' AS Race,	--Race
					m.HomeID,
					m.AwayID, 		
					m.Betstatus,
					ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
					INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid 					
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype BETWEEN 1201 AND 1299 AND
					b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) AND
					b.statusID  IN (111,112,113)
				
				INSERT INTO @BetListByDateMem
				SELECT
					r.Sporttype, 
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.Bettype,
					b.hdp1, 
					b.hdp2,
					0 as OddsType, 
					b.odds, 
					b.modds,
					b.Stake, 
					b.actual_stake,
					'' as betteam, 
					b.status AS Status,				
					b.refno,
					b.Transdate,	
					b.winlostdate,			
					(b.winlost-actual_stake),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0 as Liveindicator,
					b.Livehomescore,
					b.Liveawayscore,
					b.IP AS IP,
					r.LeagueID,
					b.MatchID,	
					o.RacerNum as MatchCode,
					b.oddsid as Race,	
					o.RacerID as homeID,
					0 as awayID,		
					'' Betstatus,
					CONVERT(BIT,0) as IsNeutral,
					b.custid,
					r.EventTime as showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)		
					INNER JOIN VSOutright14 o with (NOLOCK) ON b.oddsid = o.Orid
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND --to improve performance
					b.custid=@_CustID AND
					b.bettype IN (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) AND
					b.statusID  IN (111,112,113)
			END

		-- Playtech Casino - Progressive bonus
		IF @ShowProgressiveBonus = 1
		BEGIN
			INSERT INTO @BetListByDateMem
				SELECT
					251, --Sporttype
					@Username, 
					b.TransID,
					ISNULL(b.BetID,0),
					b.bettype,
					0, 
					0,
					0 AS OddsType,  
					0 as Odds, 
					0 as Modds, 
					b.Stake, 
					b.actual_stake,
					'', --Betteam
					b.Status,
					b.Refno,				
					b.Transdate,	
					b.winlostdate,						
					b.winlost-actual_stake,
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					
					b.PlayerComm,
					(b.comm - b.playercomm) AS comm,
					(b.acomm - b.comm) AS acomm ,
					(b.scomm - b.acomm) AS scomm,
					
					b.APositiontaking,
					b.MPositiontaking,
					b.SPositiontaking,
					
					b.discount,
					b.adiscount,
					b.sdiscount,
					
					0,
					0,
					0,
					b.IP AS IP,
					0, --LeagueID
					0, --MatchID	
					'',--MatchCode
					'',--Race
					0, --HomeID
					0, --AwayID		
					0, --Betstatus
					CONVERT(BIT,0) AS IsNeutral,
					b.custid,
					'' showtime,
					'' as betcheck,
					CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
				FROM
					dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)
				WHERE
					b.winlostdate BETWEEN @fromdate AND @todate AND
					b.recommend = @Recommend AND
					b.custid=@_CustID AND
					b.bettype = 72 AND
					--b.status not in ('running','waiting') and
					b.statusID  IN (111,112,113)
					
		END

		--Keno
		IF @ShowKeno = 1
		BEGIN	
			INSERT INTO @BetListByDateMem
			SELECT
				202 AS Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2,
				b.OddsType,
				b.odds, 
				b.modds,
				b.Stake, 
				b.actual_stake,
				fnc.ChoiceId AS Betteam,
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				b.PlayerComm,
				(b.comm - b.playercomm) AS comm,
				(b.acomm - b.comm) AS acomm ,
				(b.scomm - b.acomm) AS scomm,
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				
				b.discount,
				b.adiscount,
				b.sdiscount,
				
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0 LeagueID,
				fnc.GameId AS MatchID,	
				'' AS MatchCode,
				'' AS Race,	
				0 AS HomeID,
				0 AS AwayID, 		
				0 AS Betstatus,
				CONVERT(BIT, 0) AS IsNeutral,
				b.custid,
				'' AS showtime,
				'' AS betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK)
				CROSS APPLY dbo.f_ParseTransDesc(b.transdesc, b.bettype) AS fnc
			WHERE
				b.winlostdate BETWEEN @fromdate AND @todate AND
				b.recommend = @Recommend AND  
				b.custid = @_CustID AND
				b.bettype BETWEEN 1501 AND 1599 AND
				b.statusID  IN (111,112,113)					
		END
		
	END		
		
	-- check to show mix-parlay ticket
	IF(EXISTS(SELECT TOP 1 1 FROM @BetListByDateMem))
	BEGIN

		IF @ShowRB = 1
		BEGIN

			IF @Todate > @MoveBetsDay 
			BEGIN
				INSERT INTO @BettransDetail
				SELECT 
					BM.refno, 
					BM.odds, 
					BM.stake,
					BM.status, 
					BM.apositiontaking, 
					BM.mpositiontaking, 
					BM.spositiontaking,
					BM.bettype,
					BM.Betteam  
				FROM dbo.bettransm BM WITH (NOLOCK, index=IX_bettransm)
				INNER JOIN @BetListByDateMem B ON BM.refno = B.transid and BM.custid = b.custid
				WHERE B.Bettype IN (33,43)
			END
			
		IF @Fromdate <= @MoveBetsDay
		BEGIN
			INSERT INTO @BettransDetail
			SELECT 
				BM.refno, 
				BM.odds, 
				BM.stake,
				BM.status, 
				BM.apositiontaking, 
				BM.mpositiontaking, 
				BM.spositiontaking,
				BM.bettype,
				BM.Betteam
			FROM dbo.bettransm14 BM WITH (NOLOCK, index=IX_bettransm14)
			INNER JOIN @BetListByDateMem B ON BM.refno = B.transid and BM.custid = b.custid
			WHERE B.Bettype IN (33,43)
		END	
		
	END

	IF @ShowVS = 1
	BEGIN
		IF @Todate > @MoveBetsDay 
		BEGIN
			INSERT INTO @BettransDetail
			SELECT 
				BM.refno, 
				BM.odds, 
				BM.stake,
				BM.status, 
				BM.apositiontaking, 
				BM.mpositiontaking, 
				BM.spositiontaking,
				BM.bettype,
				BM.Betteam  
			FROM dbo.bettransm BM WITH (NOLOCK, index=IX_bettransm)
			INNER JOIN @BetListByDateMem B ON BM.refno = B.RefNO and BM.custid = b.custid
			WHERE B.Bettype = 1233
		END
			
		IF @Fromdate <= @MoveBetsDay
		BEGIN
			INSERT INTO @BettransDetail
			SELECT 
				BM.refno, 
				BM.odds, 
				BM.stake,
				BM.status, 
				BM.apositiontaking, 
				BM.mpositiontaking, 
				BM.spositiontaking,
				BM.bettype,
				BM.Betteam
			FROM dbo.bettransm14 BM WITH (NOLOCK, index=IX_bettransm14)
			INNER JOIN @BetListByDateMem B ON BM.refno = B.RefNO and BM.custid = b.custid
			WHERE B.Bettype = 1233
		END	
		
	END

	IF @ShowLiveCasino = 1
	BEGIN

		IF @Todate > @MoveBetsDay 
		BEGIN
			INSERT INTO @BettransDetail
			SELECT 
				BG.refno, 
				BG.odds, 
				BG.stake,
				BG.status, 
				BG.apositiontaking, 
				BG.mpositiontaking, 
				BG.spositiontaking,
				BG.bettype,
				BG.Betteam 
			FROM dbo.bettransg BG WITH (NOLOCK, index=IX_bettransg)
			INNER JOIN @BetListByDateMem B ON BG.refno = B.refno and BG.custid = b.custid
			WHERE B.Bettype BETWEEN 1101 AND 1199
		END
		
		IF @Fromdate <= @MoveBetsDay
		BEGIN
			INSERT INTO @BettransDetail
			SELECT 
				BG.refno, 
				BG.odds, 
				BG.stake,
				BG.status, 
				BG.apositiontaking, 
				BG.mpositiontaking, 
				BG.spositiontaking,
				BG.bettype ,
				BG.Betteam 
			FROM dbo.bettransg14 BG WITH (NOLOCK, index=IX_bettransg14)
			INNER JOIN @BetListByDateMem B ON BG.refno = B.refno and BG.custid = b.custid
			WHERE B.Bettype BETWEEN 1101 AND 1199
		END	
		
	END
	
	END

	-- member betlist
	SELECT * 
	FROM  @BetListByDateMem 
	ORDER BY TransID 

	-- member betlist - mix-parlay
	SELECT * 
	FROM @BettransDetail 
	ORDER BY RefNo
		, Bettype
	
	SELECT @Duration = DATEDIFF(millisecond, @startRun, GETDATE());
		
	RETURN
END
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_SelWinLossByDate] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BetList_SelWinLossByDate] TO [bodbDownlineNet] AS [dbo]
GO
