ALTER  PROCEDURE [dbo].[Aff_User_BetListResult_SelMatch]
	@LicenseeID INT ,
	@UserID		INT,	
	@MatchID INT,
	@RaceNo VARCHAR(50)=NULL
AS
 
/*
Created: Long.Luu@3Dec2013
Task: Get Result of match
DB: DB052.bodb02
Original: Lrf_BetList_SelMatchResult

Revisions:    
	
	*******************
	sample test case:
		exec Lrf_BetList_SelMatchResult_xtest @licenseeid=1,@matchid=2715481,@raceno=N'3',@userid=68
*/

SET NOCOUNT ON

IF(@RaceNo is NULL )
BEGIN
	IF exists(SELECT 1 FROM match WITH(NOLOCK) WHERE matchid = @matchid)
	BEGIN	
		SELECT 
			m.sporttype, 
			m.betstatus, 
			hthomescore,
			htawayscore,
			CASE WHEN m.sporttype NOT IN (162,161)
				 THEN datediff(minute,GlobalShowTime,CURRENT_TIMESTAMP)
				 ELSE datediff(minute,kickofftime,CURRENT_TIMESTAMP)
				 END playtime,
			m.LeagueID,
			m.matchid, 
			m.homeID,
			m.awayID,
			m.matchcode,
			CASE WHEN m.sporttype NOT IN (162,161)
				THEN m.GlobalShowTime
				ELSE m.kickofftime
				END kickofftime,
			m.eventdate,
			m.finalhomescore,
			m.finalawayscore,
			case when m.betstatus like 'Refund FT%' then 'Refund FT' 
						 when m.betstatus like 'Refund HT%' then 'Refund HT'
						 when m.betstatus like 'Refund%' then 'Refund' 
						else m.eventstatus end as eventstatus,
			isnull(mr.refund,0) IsRefund, 
			isnull(mr.calrefund,0) IsCalRefund,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			m.goalrecord,
			ISNULL(mr.IsHTCal,0) as IsHTCal,
			ISNULL(mr.calculate,0) as calculate	,
			ISNULL(mr.IsPending,0) as IsPending	 ,
			ISNULL(m.showtime,'') AS showtime,
			m.homeid2
		FROM match m WITH(NOLOCK)
			LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
		WHERE m.matchid = @matchid
		ORDER BY m.eventdate,m.matchcode
		RETURN
	END
	IF exists(SELECT 1 FROM match14 WITH(NOLOCK) WHERE matchid = @matchid)
			 	
	BEGIN
		SELECT 
			m.sporttype, 
			m.betstatus, 
			hthomescore,
			htawayscore,
			CASE WHEN m.sporttype NOT IN (162,161)
				 THEN datediff(minute,GlobalShowTime,CURRENT_TIMESTAMP)
				 ELSE datediff(minute,kickofftime,CURRENT_TIMESTAMP)
				 END playtime,
			m.LeagueID,
			m.matchid, 
			m.homeID,
			m.awayID,
			m.matchcode,
			CASE WHEN m.sporttype NOT IN (162,161)
				THEN m.GlobalShowTime
				ELSE m.kickofftime
				END kickofftime,
			m.eventdate,
			m.finalhomescore,
			m.finalawayscore,
			case when m.betstatus like 'Refund FT%' then 'Refund FT' 
						 when m.betstatus like 'Refund HT%' then 'Refund HT'
						 when m.betstatus like 'Refund%' then 'Refund' 
						else m.eventstatus end as eventstatus,
			isnull(mr.refund,0) IsRefund, 
			isnull(mr.calrefund,0) IsCalRefund,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			m.goalrecord,
			ISNULL(mr.IsHTCal,0) as IsHTCal,
			ISNULL(mr.calculate,0) as calculate,
			ISNULL(mr.IsPending,0) as IsPending	 ,
			ISNULL(m.showtime,'') AS showtime,
			m.homeid2
		FROM match14 m WITH(NOLOCK)		
			LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
		WHERE m.matchid = @matchid
		ORDER BY m.eventdate,m.matchcode
		RETURN
	END
	ELSE
	BEGIN
		SELECT 
			m.sporttype, 
			m.betstatus, 
			hthomescore,
			htawayscore,
			CASE WHEN m.sporttype NOT IN (162,161)
				 THEN datediff(minute,GlobalShowTime,CURRENT_TIMESTAMP)
				 ELSE datediff(minute,kickofftime,CURRENT_TIMESTAMP)
				 END playtime,
			m.LeagueID,
			m.matchid, 
			m.homeID,
			m.awayID,
			m.matchcode,
			m.eventdate,
			CASE WHEN m.sporttype NOT IN (162,161)
				THEN m.GlobalShowTime
				ELSE m.kickofftime
				END kickofftime,
			m.finalhomescore,
			m.finalawayscore,
			case when m.betstatus like 'Refund FT%' then 'Refund FT' 
						 when m.betstatus like 'Refund HT%' then 'Refund HT'
						 when m.betstatus like 'Refund%' then 'Refund' 
						else m.eventstatus end as eventstatus,
			isnull(mr.refund,0) IsRefund,  
			isnull(mr.calrefund,0) IsCalRefund,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			m.goalrecord,
			ISNULL(mr.IsHTCal,0) as IsHTCal,
			ISNULL(mr.calculate,0) as calculate,
			ISNULL(mr.IsPending,0) as IsPending,
			ISNULL(m.showtime,'') AS showtime,
			m.homeid2
		FROM DB06.bodb_archive.dbo.Match_BK m WITH(NOLOCK)		
			LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
		WHERE m.matchid = @matchid
		ORDER BY m.eventdate,m.matchcode
	END
END
ELSE
BEGIN
	CREATE TABLE  #tmpresult (horseNo varchar(50),KickoffTime datetime ,racename varchar(50),place tinyint,sporttype INT,horseid INT, odds smallmoney,PlaceOdds smallmoney,meetingid int,oddsstatus varchar(10),IsFavor varchar(10),IsSCR bit,FOddsStatus varchar(10))
	DECLARE	@leagueid INT, @eventdate DATETIME 
	IF exists(select 1 from outright WITH(NOLOCK) where orid = @matchid)
	BEGIN
		SELECT	@leagueid = leagueid , @eventdate = eventdate 
		FROM	Outright WITH (NOLOCK)
		WHERE	orid = @matchid 
		insert into #tmpresult 
		SELECT	matchcode AS horseNo, 
				NULL,
				CAST(o.groupmatch AS INT) 
				AS racename,
				CASE WHEN o.placing = 0 THEN 5 ELSE isnull(placing,5) END place, 
				l.sporttype, 
				teamid horseid,
				o.odds,
				o.placeodds,
				o.leagueid AS meetingid,
				o.oddsstatus status,
				convert(varchar(10),o.IsFavor),
				o.IsSCR,
				o.FOddsStatus
		FROM	Outright o WITH (NOLOCK)	
					INNER JOIN league l WITH(NOLOCK) ON o.leagueid = l.leagueid
		WHERE	o.leagueid = @leagueid 
				AND groupmatch = @RaceNo
				AND eventdate = @eventdate 
				AND ( ISNULL(placing,0) <> 0 OR isScr = 1)
		ORDER BY placing
		
	END 
	ELSE IF EXISTS( SELECT 1 FROM Outright14 WITH (NOLOCK) WHERE orid = @matchid)
	BEGIN
		SELECT	@leagueid = leagueid , @eventdate = eventdate 
		FROM	Outright14 WITH (NOLOCK)
		WHERE	orid = @matchid 
		insert into #tmpresult 
		SELECT	matchcode AS horseNo, 
				NULL,
				CAST(o.groupmatch AS INT) AS racename,
				CASE WHEN o.placing = 0 THEN 5 ELSE isnull(placing,5) END place, 
				l.sporttype, 
				teamid horseid,
				o.odds,
				o.placeodds,
				o.leagueid AS meetingid,
				o.oddsstatus status,
				convert(varchar(10),o.IsFavor),
				o.IsSCR,
				o.FOddsStatus
		FROM	Outright14 o WITH (NOLOCK)
					INNER JOIN league l WITH(NOLOCK) ON l.leagueid = o.leagueid
		WHERE	o.leagueid = @leagueid 
				AND groupmatch = @RaceNo
				AND eventdate = @eventdate 
				AND (ISNULL(placing,0) <> 0  OR isScr = 1)
		ORDER BY placing	
	END 
	ELSE  IF EXISTS( SELECT 1 FROM DB06.bodb_Archive.dbo.Outright_bk WITH (NOLOCK) WHERE orid = @matchid)
	BEGIN
		SELECT	@leagueid = leagueid , @eventdate = eventdate 
		FROM	DB06.bodb_Archive.dbo.Outright_bk WITH (NOLOCK)
		WHERE	orid = @matchid 
		insert into #tmpresult 
		SELECT	matchcode AS horseNo, 
				NULL,
				CAST(bk.groupmatch AS INT) AS racename,
				CASE WHEN placing = 0 THEN 5 ELSE isnull(placing,5) END place, 
				l.sporttype, 
				teamid horseid,
				bk.odds,
				bk.placeodds,
				bk.leagueid AS meetingid,
				bk.oddsstatus status,
				convert(varchar(10),IsFavor),
				bk.IsSCR,
				bk.FOddsStatus
		FROM	DB06.bodb_Archive.dbo.Outright_bk bk WITH (NOLOCK)
					INNER JOIN league l WITH(NOLOCK) ON l.leagueid = bk.leagueid
		WHERE	bk.leagueid = @leagueid 
				AND groupmatch = @RaceNo
				AND eventdate = @eventdate 
				AND (ISNULL(placing,0)<> 0  OR isScr = 1)
		ORDER BY placing	
	END 
	--------------------------------------------------Virtual Horse Racing

	IF exists( SELECT TOP 1 1 FROM VSOutright WITH(NOLOCK) WHERE EventID=@MatchID)
		BEGIN
			-- Virtual HR 
			insert into #tmpresult 
			SELECT	RacerNum AS horseNo, 
					r.EventTime,
					NULL AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus status,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	VSOutright o WITH (NOLOCK)
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
			
		END
		ELSE IF exists(SELECT TOP 1 1 FROM VSOutright14 WITH(NOLOCK) WHERE EventID=@MatchID)
		BEGIN
			-- Virtual HR 
			insert into #tmpresult 
			SELECT	RacerNum AS horseNo, 
					r.EventTime,
					NULL AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus status,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	VSOutright14 o WITH (NOLOCK)
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
			
		END
		ELSE 
		BEGIN
			-- Virtual HR 
			insert into #tmpresult 
			SELECT	RacerNum AS horseNo, 
					r.EventTime,
					NULL AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus status,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	DBARC.bodb_Archive.dbo.VSOutright_bk o WITH (NOLOCK)
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
			
		END
	--------------------------------------------------End Virtual Horse Racing
	IF EXISTS (SELECT 1 FROM #tmpresult  WHERE sporttype in (151,152,153))
		BEGIN 
				SELECT meetingid,racename,COUNT(place) rc INTO #DataSUM
				FROM #tmpresult
				WHERE place<5
				GROUP BY   meetingid,racename
				
				SELECT 	d.meetingid
				,d.racename
				,temp.results as TF
				,temp2.results2 as SCR
				INTO #tmp	
				FROm #tmpresult d
				INNER JOIN #DataSum d2 ON d.meetingid=d2.meetingid AND  d.racename=d2.racename
				CROSS APPLY  (
							  SELECT STUFF (
											(
											SELECT  CAST(horseNo AS VARCHAR(10))+ ',' 
														
											FROM #tmpresult d
											WHERE d.meetingid=d2.meetingid AND  d.racename=d2.racename  AND d.IsFavor<>'0' 
											for xml path(''), type).value('.','varchar(max)')
											,1,2,''
											)
							  )temp(results)	
				
				CROSS APPLY  (
							  SELECT STUFF (
											(
											SELECT CAST(horseNo AS VARCHAR(10))+ ',' 
											FROM #tmpresult d
											WHERE d.meetingid=d2.meetingid AND  d.racename=d2.racename  AND d.IsSCR<>0
											for xml path(''), type).value('.','varchar(max)')
											,1,2,''
											)
							  )temp2(results2)	
				ORDER BY d.meetingid,d.racename,d.place
			
				SELECT DISTINCT
				 d.*
				,d3.TF
				,d3.SCR		
				,d2.rc as [RowCount]  
				FROm #tmpresult d
				INNER JOIN #DataSum d2 ON d.meetingid=d2.meetingid AND  d.racename=d2.racename
				INNER JOIN #tmp d3 ON d.meetingid=d3.meetingid AND  d.racename=d3.racename
				WHERE d.place<5 
				ORDER BY d.meetingid,d.racename,d.place
		
				DROP TABLE #DataSum 
				DROP TABLE #tmp
		END--
	ELSE IF EXISTS (SELECT 1 FROM  #tmpresult  WHERE sporttype=181)
		BEGIN 
			SELECT kickofftime,COUNT(place) rc INTO #DataSUMVHR
			FROM #tmpresult
			GROUP BY  kickofftime

			SELECT d.*,'' TF,'' SCR , d2.rc as [RowCount]  
			FROm #tmpresult d
			INNER JOIN #DataSumVHR d2 ON d.kickofftime=d2.kickofftime 
			WHERE d.place<5
			ORDER BY meetingid, kickofftime,place
			DROP TABLE #DataSumVHR 
		END --
	ELSE 
		BEGIN 
			SELECT * FROM #tmpresult 
		END 	
	DROP TABLE #tmpresult 
END
GO

GRANT EXECUTE ON [dbo].[Aff_User_BetListResult_SelMatch] TO [bodbadminNet]