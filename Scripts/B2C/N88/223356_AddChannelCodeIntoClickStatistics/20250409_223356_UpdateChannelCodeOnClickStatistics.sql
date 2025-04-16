/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250408@Sophia
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Update Data for ChannelCode on ClickStatistics, ClickStatistics_BK [RedmineID: #223356]

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/
  
 

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
 
DROP TABLE #batch 
DROP TABLE #ClickStatistics 
DROP TABLE #ClickStatistics_bk