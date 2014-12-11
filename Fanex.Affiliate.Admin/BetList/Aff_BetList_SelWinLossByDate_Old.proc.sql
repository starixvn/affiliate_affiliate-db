USE [bodb_archive]
GO
ALTER PROCEDURE [dbo].[Aff_BetList_SelWinLossByDate_Old]
	@CustID 					INT
	,@FromDate 					SMALLDATETIME
	,@ToDate 					SMALLDATETIME
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
DB:	DBARC.bodb_Archive
Original: DBARC.bodb_Archive.dbo.[Age_BetList_SelWinLossByDate_Mem_Old]

Revisions:           
	20141016@Bobby.Nguyen: Initial affiliate member betlist
	
Param's Explanation: 
	- @CustID: 		Customer/Player ID
	- @FromDate: 	Date only
	- @ToDate: 		Date only
	- @Language: 	translate to which language
	- @ShowSB BIT: 	Show sportbooks
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

	DECLARE @UserName	NVARCHAR(20)
		, @Recommend	INT
		, @startRun 	DATETIME
		
	SELECT @startRun 	= GETDATE()

	SELECT TOP(1) @UserName = UserName
		, @Recommend = Recommend 
	FROM bodb02.dbo.custinfo WITH(NOLOCK) 
	WHERE CustID = @CustID
	
	IF(@UserName IS NULL)
	BEGIN
		SELECT @Error		= 101
			,@ErrorMsg		= CASE 
									WHEN @Language = 'EN' THEN 'There is not exists member.' 
									ELSE '' 
								END
		RETURN
	END
	
	CREATE TABLE #BetListByDateMem(
		Sporttype SMALLINT,
		Username nvarchar(20), 
		TransID bigint ,
		BetID bigint,
		Bettype SMALLINT,
		hdp1 smallmoney, 
		hdp2 smallmoney, 
		Modds smallmoney,
		OddsType tinyint,
		Odds smallmoney, 
		Stake money, 
		actual_stake money,
		Betteam nvarchar(20),
		Status nvarchar(10),
		RefNO bigint,	
		Transdate datetime,
		Winlostdate datetime,
		Winlost money,
		awinlost money,
		mwinlost money,
		swinlost money,
	
		PlayerComm money,
		comm money,
		acomm money,
		scomm money,
	
		APositiontaking smallmoney,
		MPositiontaking smallmoney,
		SPositiontaking smallmoney,
		Adiscount smallmoney,
		Mdiscount smallmoney,
		Sdiscount smallmoney,
		Liveindicator bit,
		Livehomescore smallint,
		Liveawayscore smallint,
		IP nvarchar(15),
		LeagueID int,
		MatchID int,
		MatchCode nvarchar(50),--VinhTrinh Add for Horseracing
		Race nvarchar(20),--VinhTrinh Add for Horseracing
		HomeID int,
		AwayID int, 	
		Betstatus nvarchar(50),
		isNeutral bit,
		custid int ,
		showtime NVARCHAR(50), -- table - shoe - hand of Live Casino
		betcheck nvarchar(50),
		comstatus NVARCHAR(20)
	)
	
	DECLARE @BettransDetail TABLE(  
		 refno BIGINT,  
		 finalodds SMALLMONEY,
		 odds SMALLMONEY,
		 stake MONEY,  
		 status NVARCHAR(10),  
		 apositiontaking SMALLMONEY,  
		 mpositiontaking SMALLMONEY,  
		 spositiontaking SMALLMONEY,
		 bettype SMALLINT,
		 Betteam nvarchar(10)
	 )   

	--Sport Book
	IF (@ShowSB = 1)
	BEGIN	
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				b.OddsType,
				b.odds, 
				b.Stake, 
				b.actual_stake,
				b.betteam,
				b.status as Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				m.LeagueID,
				m.MatchID,		
				m.MatchCode,
				'' as Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.custid,
				isnull(m.showtime,'') as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN dbo.match_BK AS m with (nolock) ON b.matchid=m.matchid 					
			WHERE
				b.winlostdate between @fromdate and @todate  
				--b.Recommend = @Recommend and
				AND b.custid=@custid  
				AND b.bettype not in (10,31,32,33,51,52,53,54,55,56,61,62,63,64,65,66)
				AND b.bettype NOT BETWEEN 81 AND 120   --- Change arrange of Numbergame from 81 to 120
				AND b.bettype NOT BETWEEN 1101 AND 1199
				AND b.bettype NOT BETWEEN 1201 AND 1299
				AND b.bettype NOT BETWEEN 1501 AND 1599 -- exclude Keno
				

		-- Mix Parlay		

		INSERT INTO #BetListByDateMem
			SELECT
				0, --Sporttype
				@Username, 
				CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betid END AS TransID,
				isnull(b.BetID,0),
				b.bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 as OddsType,
				b.Odds, 
				b.Stake, 
				b.actual_stake,
				b.betteam,
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) as IsNeutral,
				b.custid ,
				'' as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)					
			WHERE
				b.winlostdate between @fromdate and @todate and
				--b.Recommend = @Recommend and
				b.custid=@custid and			
				b.bettype IN (9,29) and
				--b.matchid = 0
				b.matchid IN (0,9,29) --should not remove 0 in Archive
				
		-- Outright		
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				0 as hdp1, 
				0 as hdp2, 
				modds,
				0 as OddsType,
				b.Odds, 
				b.Stake, 
				b.actual_stake,
				'' as Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				0 as LiveIndicator, 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP as IP,
				m.LeagueID,
				m.orid, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.teamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) as IsNeutral,
				b.custid ,
				'' as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN dbo.Outright_bk AS m with (nolock) ON b.matchid=m.orid 
				INNER JOIN bodb02.dbo.League as l with (nolock) ON m.leagueID = l.leagueID
			WHERE
				b.winlostdate between @fromdate and @todate and
				--b.Recommend = @Recommend and
				b.custid=@custid and			
				b.bettype = 10
	END
	
	--Horse Racing
	IF (@ShowRB = 1)
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2,
				modds,
				0 as OddsType, 
				b.Odds, 
				b.Stake, 
				b.actual_stake,
				'' as Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				0 as LiveIndicator, 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP as IP,
				m.LeagueID,
				m.orid, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.teamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) as IsNeutral,
				b.custid,
				'' as showtime ,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN dbo.Outright_bk AS m with (nolock) ON b.matchid=m.orid 
				INNER JOIN bodb02.dbo.League as l with (nolock) ON m.leagueID = l.leagueID
			WHERE
				b.winlostdate between @fromdate and @todate and
				--b.Recommend = @Recommend and
				b.custid=@custid and			
				b.bettype in (31, 32, 33,41,42,43)
	
	END
		
	-- Casino
	IF (@ShowCasino = 1)
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				251, --Sporttype
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				0 as hdp1, 
				0 as hdp2, 
				modds,
				0 as OddsType,
				0 as Odds, 
				b.Stake, 
				b.actual_stake,
				'' as Betteam, --Betteam
				b.Status,				
				b.RefNo,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				0 as Liveindicator,
				0 as Livehomescore,
				0 as Liveawayscore,
				b.IP as IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) as IsNeutral,
				b.custid ,
				'' as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
			WHERE
				b.winlostdate between @fromdate and @todate and
				--b.Recommend = @Recommend and
				b.custid=@custid and			
				b.bettype = 71
	END
	
	--Number Game
	IF (@ShowNG = 1)
	BEGIN	
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				0 as hdp2, 
				modds,
				b.OddsType, 
				b.odds, 
				b.Stake, 
				b.actual_stake,
				b.Betteam,
				b.status as Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
					
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
					
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				m.LeagueID,
				m.MatchID,		
				m.MatchCode,
				'' as Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				CONVERT(BIT,0) as IsNeutral,
				b.custid,
				'' as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus 
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN dbo.match_BK AS m with (nolock) ON b.matchid=m.matchid 					
			WHERE
				b.winlostdate between @fromdate and @todate and
				b.custid=@custid and
				b.bettype BETWEEN 81 AND 120
		END
		
	
	--- Live Casino	
	IF (@ShowLiveCasino = 1)
	BEGIN	
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				0 as hdp1, 
				0 as hdp2, 
				modds,
				b.OddsType, 
				b.odds, 
				b.Stake, 
				b.actual_stake,
				b.Betteam,
				b.status as Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
					
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
					
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				m.LeagueID,
				m.MatchID,		
				m.MatchCode,
				'' as Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				CONVERT(BIT,0) as IsNeutral,
				b.custid,
				m.showtime ,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN dbo.match_BK AS m with (nolock) ON b.matchid=m.matchid 					
			WHERE
				b.winlostdate between @fromdate and @todate and
				b.custid=@custid and
				b.bettype BETWEEN 1101 AND 1199
		END
			
	IF (@ShowVS = 1)
	BEGIN	
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				b.OddsType,
				b.odds, 
				b.Stake, 
				b.actual_stake,
				b.betteam,
				b.status as Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				m.LeagueID,
				m.MatchID,		
				m.MatchCode,
				'' as Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.custid,
				isnull(m.showtime,'') as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN dbo.match_BK AS m with (nolock) ON b.matchid=m.matchid 					
			WHERE
				b.winlostdate between @fromdate and @todate  
				--b.Recommend = @Recommend and
				AND b.custid=@custid  
				AND b.bettype between 1201 and 1299
				
			INSERT INTO #BetListByDateMem
			SELECT
				r.Sporttype, 
				@Username, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2,
				b.modds,
				0 as OddsType, 
				b.odds, 
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
				o.racerNum as MatchCode,
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
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
				INNER JOIN VSOutright_bk o with (NOLOCK) ON b.oddsid = o.Orid
				INNER JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE
				b.winlostdate between @fromdate and @todate  
				--b.Recommend = @Recommend and
				AND b.custid=@custid  
				AND b.bettype IN (1231, 1232, 1233, 1237, 1238)
	END

	IF (@ShowProgressiveBonus = 1)
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				251, --Sporttype
				@Username, 
				b.TransID,
				isnull(b.BetID,0),
				b.Bettype,
				0 as hdp1, 
				0 as hdp2, 
				modds,
				0 as OddsType,
				0 as Odds, 
				b.Stake, 
				b.actual_stake,
				'' as Betteam, --Betteam
				b.Status,				
				b.RefNo,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				0 as Liveindicator,
				0 as Livehomescore,
				0 as Liveawayscore,
				b.IP as IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) as IsNeutral,
				b.custid ,
				'' as showtime,
				'' betcheck,
				CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
			FROM
				dbo.bettrans_bk AS b with (nolock, index=IX_custid)		
			WHERE
				b.winlostdate between @fromdate and @todate and
				--b.Recommend = @Recommend and
				b.custid=@custid and			
				b.bettype = 72
	END

	--Keno
	IF @ShowKeno = 1
	BEGIN	
		INSERT INTO #BetListByDateMem
		SELECT
			202 AS Sporttype, 
			@Username, 
			b.TransID,
			ISNULL(b.BetID, 0),
			b.Bettype,
			0 AS hdp1, 
			0 AS hdp2,
			b.modds,
			b.OddsType, 
			b.odds,
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
			dbo.bettrans_bk AS b WITH (NOLOCK, index=ix_custid)
			CROSS APPLY dbo.f_ParseTransDesc(b.transdesc, b.bettype) AS fnc
		WHERE b.winlostdate BETWEEN @fromdate AND @todate
			AND b.recommend = @Recommend
			AND b.custid = @CustID 
			AND b.bettype BETWEEN 1501 AND 1599 
			--AND b.statusID NOT IN (0, 1)
	END
	

	IF(EXISTS(SELECT TOP 1 1 FROM #BetListByDateMem))
	BEGIN
	
		IF @ShowRB = 1
		BEGIN
			--get data from bettransm for bettype 33,43
			INSERT INTO @BettransDetail
			SELECT 
				BM.refno, 
				0 as finalodds,
				BM.odds, 
				BM.stake,
				BM.status, 
				BM.apositiontaking, 
				BM.mpositiontaking, 
				BM.spositiontaking,
				BM.bettype ,
				BM.Betteam  
			FROM dbo.bettransm BM with (NOLOCK, INDEX=IX_bettransm)
			INNER JOIN #BetListByDateMem B ON BM.refno = B.transid and BM.custid = b.custid
			WHERE B.Bettype IN (33,43)
			ORDER BY RefNo,Bettype
		END

		IF (@ShowVS = 1)
		BEGIN
			INSERT INTO @BettransDetail
			SELECT 
				BM.refno, 
				0 as finalodds,
				BM.odds, 
				BM.stake,
				BM.status, 
				BM.apositiontaking, 
				BM.mpositiontaking, 
				BM.spositiontaking,
				BM.bettype ,
				BM.Betteam  
			FROM dbo.bettransm BM WITH (NOLOCK, INDEX=IX_bettransm)
			INNER JOIN #BetListByDateMem B ON BM.refno = B.refno and BM.custid = b.custid
			WHERE B.Bettype = 1233
			ORDER BY RefNo,Bettype
		END

		IF (@ShowLiveCasino = 1)
		BEGIN
			--get data from bettransg
			INSERT INTO @BettransDetail
			SELECT 
				BG.refno, 
				0 as finalodds,
				BG.odds, 
				BG.stake,
				BG.status, 
				BG.apositiontaking, 
				BG.mpositiontaking, 
				BG.spositiontaking,
				BG.bettype,
				BG.Betteam   
			FROM dbo.bettransg BG with (NOLOCK, index=IX_bettransg)
			INNER JOIN #BetListByDateMem B ON BG.refno = B.refno and BG.custid = b.custid
			WHERE B.Bettype BETWEEN 1101 AND 1199
			ORDER BY RefNo,Bettype
		END

	END
	
	-- member betlist
	SELECT * 
	FROM  #BetListByDateMem 
	ORDER BY TransID

	-- member betlist - mix-parlay
	SELECT * 
	FROM  @BettransDetail 
	ORDER BY Refno

	DROP TABLE #BetListByDateMem

	SELECT @Duration = DATEDIFF(millisecond, @startRun, GETDATE());
		
	RETURN
	
END
GO
GRANT EXECUTE ON [dbo].[Aff_BetList_SelWinLossByDate_Old] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_SelWinLossByDate_Old] TO [bodbDownlineNet] AS [dbo]
GO