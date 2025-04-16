/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250408@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Update Data for ChannelCode on ClickStatistics, ClickStatistics_BK [RedmineID: #222765]
		 

*/

USE [Affiliate_12B]
GO

DECLARE @BatchSize INT = 2000
CREATE TABLE #batch (ClickId INT PRIMARY KEY, ChannelCode VARCHAR(50))

-----------ClickStatistics_bk
CREATE TABLE #ClickStatistics_bk (ClickId INT PRIMARY KEY, ChannelCode VARCHAR(50))

INSERT INTO #ClickStatistics_bk (ClickId, ChannelCode)
Select r.ClickId,  l.ChannelCode 
from ClickStatistics_bk r WITH (NOLOCK)  
INNER JOIN dbo.Market m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
INNER JOIN Affmedialink l (NOLOCK) ON l.AffMediaLink = r.AffMediaLink and r.AffID = l.AffId AND l.LanguageCode = m.MarketId
WHERE ISNULL(r.ChannelCode, '') <> ISNULL(l.ChannelCode,'')

WHILE (1=1)
BEGIN
	TRUNCATE TABLE #batch

	DELETE TOP (@BatchSize) T
	OUTPUT deleted.ClickId, deleted.ChannelCode
		INTO #batch(ClickId,ChannelCode)
	FROM #ClickStatistics_bk t 

	IF @@ROWCOUNT = 0 BREAK
	 
	UPDATE a
	SET a.ChannelCode = b.ChannelCode
	FROM ClickStatistics_bk a WITH (ROWLOCK, UPDLOCK)
	INNER JOIN #batch b ON a.ClickId = b.ClickId
	
	WAITFOR DELAY '00:00:00:280'

END	

-----------ClickStatistics
CREATE TABLE #ClickStatistics (ClickId INT PRIMARY KEY, ChannelCode VARCHAR(50))

INSERT INTO #ClickStatistics (ClickId, ChannelCode)
Select r.ClickId,  l.ChannelCode 
from ClickStatistics r WITH (NOLOCK)  
INNER JOIN dbo.Market m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
INNER JOIN Affmedialink l (NOLOCK) ON l.AffMediaLink = r.AffMediaLink and r.AffID = l.AffId AND l.LanguageCode = m.MarketId
WHERE ISNULL(r.ChannelCode, '') <> ISNULL(l.ChannelCode,'')

WHILE (1=1)
BEGIN
	TRUNCATE TABLE #batch

	DELETE TOP (@BatchSize) T
	OUTPUT deleted.ClickId, deleted.ChannelCode
		INTO #batch(ClickId,ChannelCode)
	FROM #ClickStatistics t 

	IF @@ROWCOUNT = 0 BREAK
	 
	UPDATE a
	SET a.ChannelCode = b.ChannelCode
	FROM ClickStatistics a WITH (ROWLOCK, UPDLOCK)
	INNER JOIN #batch b ON a.ClickId = b.ClickId
	
	WAITFOR DELAY '00:00:00:280'

END	

 