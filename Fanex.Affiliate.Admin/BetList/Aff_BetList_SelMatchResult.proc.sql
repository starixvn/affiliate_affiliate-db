USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_BetList_SelMatchResult]    Script Date: 10/17/2014 8:31:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_BetList_SelMatchResult]
	@MatchID 		INT
	,@Bettype 		SMALLINT 	= NULL
	,@BetId	 		BIGINT 		= NULL
	,@RaceNo 		VARCHAR(50)	= NULL	
AS

/*
Created:20141017@Bobby.Nguyen
Task: Get Result Page
DB: DBEXT/bodb02
Orgiginal: DBEXT/bodb02.dbo.Age_BetList_SelMatchResult

Revisions:    
	- 20141017@Bobby.Nguyen: Initial SP & Get the detail information of Tennis sport
	- 20141229@Bobby.Nguyen: add more homeid2 & awayid2 column
*/
BEGIN
	SET NOCOUNT ON
	
	IF(@RaceNo IS NULL )
	BEGIN
		DECLARE @ResourceId VARCHAR(20) 
		SELECT @ResourceId = LEFT(REPLACE(CONVERT(VARCHAR(20),@BetId), '8', '' ),2)
		
		IF (EXISTS(SELECT 1 FROM dbo.[match] WITH(NOLOCK) WHERE matchid = @matchid))
		BEGIN	
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				CASE WHEN m.sporttype = 162
					 THEN DATEDIFF(MINUTE, m.kickofftime ,CURRENT_TIMESTAMP) 
					 ELSE DATEDIFF(MINUTE, ISNULL(m.GlobalShowTime, m.kickofftime) ,CURRENT_TIMESTAMP) 
				END playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				CASE WHEN m.sporttype = 162 
					 THEN m.kickofftime
					 ELSE m.GlobalShowTime
				END kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				CASE WHEN m.betstatus like 'Refund FT%' THEN 'Refund FT' 
							 when m.betstatus like 'Refund HT%' THEN 'Refund HT'
							 when m.betstatus like 'Refund%' THEN 'Refund' 
							ELSE m.eventstatus END AS eventstatus,
				ISNULL(mr.refund,0) IsRefund, 
				ISNULL(mr.calrefund,0) IsCalRefund,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) AS IsHTCal,
				ISNULL(mr.calculate,0) AS calculate	,
				ISNULL(mr.IsPending,0) AS IsPending	,
				m.showtime
				,m.homeid2
				,m.awayid2
			FROM dbo.match m WITH(NOLOCK)
				LEFT OUTER JOIN dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
								
			SELECT	D.MatchId,
					D.ResourceId,
					D.HomeValue,
					D.AwayValue,
					D.ResultStatusID,
					D.SettlementStatusID
			FROM	dbo.ResultDetail D WITH (NOLOCK)			
			WHERE	D.MatchId = @MatchId					
					AND (@Bettype IS NULL OR CASE WHEN @Bettype NOT IN (1324) THEN 2 ELSE 
							CASE WHEN @Bettype IN (1324) AND LEFT(D.ResourceId,2) = @ResourceId THEN 4 
								ELSE 0 END END = LEN(D.ResourceId)
							)

			ORDER BY ResourceId

			RETURN
		END
		IF exists(SELECT 1 FROM dbo.match14 WITH(NOLOCK) WHERE matchid = @matchid)	
		BEGIN
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				CASE WHEN m.sporttype = 162
					 THEN DATEDIFF(MINUTE, m.kickofftime ,CURRENT_TIMESTAMP) 
					 ELSE DATEDIFF(MINUTE, ISNULL(m.GlobalShowTime, m.kickofftime) ,CURRENT_TIMESTAMP) 
				END playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				CASE WHEN m.sporttype = 162 
					 THEN m.kickofftime
					 ELSE m.GlobalShowTime
				END kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				CASE WHEN m.betstatus like 'Refund FT%' THEN 'Refund FT' 
							 WHEN m.betstatus like 'Refund HT%' THEN 'Refund HT'
							 WHEN m.betstatus like 'Refund%' THEN 'Refund' 
							ELSE m.eventstatus END AS eventstatus,
				ISNULL(mr.refund,0) IsRefund, 
				ISNULL(mr.calrefund,0) IsCalRefund,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) AS IsHTCal,
				ISNULL(mr.calculate,0) AS calculate,
				ISNULL(mr.IsPending,0) AS IsPending	,
				m.showtime
				,m.homeid2
				,m.awayid2
			FROM dbo.match14 m WITH(NOLOCK)		
				LEFT OUTER JOIN dbo.match_remark mr WITH(NOLOCK) 
				ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode

			SELECT	D.MatchId,
					D.ResourceId,
					D.HomeValue,
					D.AwayValue,
					D.ResultStatusID,
					D.SettlementStatusID
			FROM	dbo.ResultDetail14 D WITH (NOLOCK)			
			WHERE	D.MatchId = @MatchId	
					AND  (@Bettype IS NULL OR CASE WHEN @Bettype NOT IN (1324) THEN 2 ELSE 
							CASE WHEN @Bettype IN (1324) AND LEFT(D.ResourceId,2) = @ResourceId THEN 4 
								ELSE 0 END END = LEN(D.ResourceId)
								)
			ORDER BY ResourceId

			RETURN
		END
		ELSE
		BEGIN
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				CASE WHEN m.sporttype = 162
					 THEN DATEDIFF(MINUTE, m.kickofftime ,CURRENT_TIMESTAMP) 
					 ELSE DATEDIFF(MINUTE, ISNULL(m.GlobalShowTime, m.kickofftime) ,CURRENT_TIMESTAMP) 
				END playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.eventdate,
				CASE WHEN m.sporttype = 162 
					 THEN m.kickofftime
					 ELSE ISNULL(m.GlobalShowTime, m.kickofftime)
				END kickofftime,
				m.finalhomescore,
				m.finalawayscore,
				CASE WHEN m.betstatus like 'Refund FT%' THEN 'Refund FT' 
							 WHEN m.betstatus like 'Refund HT%' THEN 'Refund HT'
							 WHEN m.betstatus like 'Refund%' THEN 'Refund' 
							ELSE m.eventstatus END AS eventstatus,
				ISNULL(mr.refund,0) IsRefund,  
				ISNULL(mr.calrefund,0) IsCalRefund,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) AS IsHTCal,
				ISNULL(mr.calculate,0) AS calculate,
				ISNULL(mr.IsPending,0) AS IsPending,
				m.showtime 
				,m.homeid2
				,m.awayid2
			FROM DBARC.bodb_archive.dbo.Match_BK m WITH(NOLOCK)		
				LEFT OUTER JOIN dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode

		
			SELECT	D.MatchId,
					D.ResourceId,
					D.HomeValue,
					D.AwayValue,
					D.ResultStatusID,
					D.SettlementStatusID
			FROM	DBARC.bodb_archive.dbo.ResultDetail_BK D WITH (NOLOCK)			
			WHERE	D.MatchId = @MatchId	
					AND  (@Bettype IS NULL OR CASE WHEN @Bettype NOT IN (1324) THEN 2 ELSE 
							CASE WHEN @Bettype IN (1324) AND LEFT(D.ResourceId,2) = @ResourceId THEN 4 
								ELSE 0 END END = LEN(D.ResourceId)
								)
			ORDER BY ResourceId
		END						
	END
	ELSE
	BEGIN
		DECLARE	@leagueid INT, @eventdate DATETIME 
		IF EXISTS(SELECT 1 FROM dbo.outright WITH(NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	Outright WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode AS horseNo, 
					CAST(o.groupmatch AS INT) AS racename,
					placing AS place, 
					l.sporttype, 
					teamid horseid,
					o.odds,
					o.placeodds,
					o.leagueid		AS meetingid,
					o.oddsstatus	AS [status],
					o.IsFavor,
					o.IsSCR,
					o.FOddsStatus
			FROM dbo.Outright o WITH (NOLOCK)	
					INNER JOIN dbo.league l WITH(NOLOCK) 
					ON o.leagueid = l.leagueid
			WHERE o.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND ( ISNULL(placing,0) <> 0 OR isScr = 1)		
			ORDER BY placing									
		END 
		ELSE IF EXISTS( SELECT 1 FROM dbo.Outright14 WITH (NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM dbo.Outright14 WITH (NOLOCK)
			WHERE orid = @matchid 

			SELECT	matchcode AS horseNo, 
					CAST(o.groupmatch AS INT) AS racename,
					placing AS place, 
					l.sporttype, 
					teamid horseid,
					o.odds,
					o.placeodds,
					o.leagueid AS meetingid,
					o.oddsstatus status,
					o.IsFavor,
					o.IsSCR,
					o.FOddsStatus
			FROM	dbo.Outright14 o WITH (NOLOCK)
					INNER JOIN dbo.league l WITH(NOLOCK) 
					ON l.leagueid = o.leagueid
			WHERE	o.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND (ISNULL(placing,0) <> 0  OR isScr = 1)			
			ORDER BY placing
		END 
		ELSE IF EXISTS( SELECT 1 FROM DBARC.bodb_Archive.dbo.Outright_bk WITH (NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	DBARC.bodb_Archive.dbo.Outright_bk WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode AS horseNo, 
					CAST(bk.groupmatch AS INT) AS racename,
					placing AS place, 
					l.sporttype, 
					teamid horseid,
					bk.odds,
					bk.placeodds,
					bk.leagueid AS meetingid,
					bk.oddsstatus [status],
					bk.IsFavor,
					bk.IsSCR,
					bk.FOddsStatus
			FROM DBARC.bodb_Archive.dbo.Outright_bk bk WITH (NOLOCK)
					INNER JOIN dbo.league l WITH(NOLOCK) 
					ON l.leagueid = bk.leagueid
			WHERE	bk.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND (ISNULL(placing,0)<> 0  OR isScr = 1)			
			ORDER BY placing
		END 	
		ELSE IF EXISTS(SELECT TOP 1 1 FROM dbo.VSOutright WITH(NOLOCK) WHERE orid = @RaceNo)
		BEGIN
			-- Virtual HR 
			SELECT	RacerNum AS horseNo, 
					r.EventTime AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus eventstatus,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	dbo.VSOutright o WITH (NOLOCK)
					INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
		END
		ELSE IF EXISTS(SELECT 1 FROM dbo.VSOutright14 WITH(NOLOCK) WHERE orid = @RaceNo)
		BEGIN
			-- Virtual HR 
			SELECT	RacerNum AS horseNo, 
					r.EventTime AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus eventstatus,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM dbo.VSOutright14 o WITH (NOLOCK)
					INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) 
					ON r.EventID = o.EventID
			WHERE o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
		END
		ELSE 
		BEGIN
			-- Virtual HR 
			SELECT	RacerNum AS horseNo, 
					r.EventTime AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus eventstatus,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM DBARC.bodb_Archive.dbo.VSOutright_bk o WITH (NOLOCK)
				INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) 
				ON r.EventID = o.EventID
			WHERE o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
		END
	END

END
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_SelMatchResult] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_SelMatchResult] TO [bodbDownlineNet] AS [dbo]
GO
