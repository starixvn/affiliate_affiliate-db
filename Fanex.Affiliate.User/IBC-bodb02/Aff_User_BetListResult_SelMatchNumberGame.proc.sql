ALTER PROCEDURE [dbo].[Aff_User_BetListResult_SelMatchNumberGame]  
    @MatchID INT
AS 
/*  
Created: Long.Luu@3Dec2013
Task: Get Result for number game 
DB: DB052.bodb02  
original: Age_BetList_SelMatchResultNumberGame
  
Revisions:      

*/  
  
SET NOCOUNT ON  
 
IF EXISTS(SELECT 1 FROM bingoBall WITH(NOLOCK) WHERE matchid = @matchid)  
BEGIN   
    SELECT    b.matchid,   
            b.Seq,   
            b.number,
            b.updatetime,
            m.kickofftime,
            m.eventdate,
            m.eventstatus,
            m.matchcode,
            m.leagueid
    FROM bingoBall b WITH(NOLOCK) INNER JOIN [match] m WITH(NOLOCK) ON b.matchid=m.matchid
    WHERE b.matchid = @matchid
    ORDER BY b.Seq
END
ELSE IF EXISTS(SELECT 1 FROM bingoBall14 WITH(NOLOCK) WHERE matchid = @matchid)   
BEGIN  
    SELECT    b.matchid,   
            b.Seq,   
            b.number,
            b.updatetime,
            m.kickofftime,
            m.eventdate,
            m.eventstatus,
            m.matchcode,
            m.leagueid
    FROM bingoBall14 b WITH(NOLOCK) INNER JOIN [match14] m WITH(NOLOCK) ON b.matchid=m.matchid
    WHERE b.matchid = @matchid
    ORDER BY b.Seq
END  
ELSE  
BEGIN  
    SELECT    b.matchid,   
            b.Seq,   
            b.number,
            b.updatetime,
            m.kickofftime,
            m.eventdate,
            m.eventstatus,
            m.matchcode,
            m.leagueid
    FROM DB06.bodb_archive.dbo.bingoBall_bk b WITH(NOLOCK) INNER JOIN DB06.bodb_archive.dbo.match_bk m WITH(NOLOCK)  ON b.matchid=m.matchid
    WHERE m.matchid = @matchid 
    ORDER BY b.Seq 
END
GO

GRANT EXECUTE ON [dbo].[Aff_User_BetListResult_SelMatchNumberGame] TO [bodbadminNet]
