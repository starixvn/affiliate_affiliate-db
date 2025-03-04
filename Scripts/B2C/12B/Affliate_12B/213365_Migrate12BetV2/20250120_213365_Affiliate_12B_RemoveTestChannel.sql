/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250220@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Remove Channel Test [RedmineID: #212201]


*/
USE Affiliate_12B
GO
DECLARE @AffId INT = 1197664
	, @Channelcode VARCHAR(50)  = 'test'

PRINT 'Delete ClickStatistics'
;WITH CTE_AffLink AS(
	SELECT REPLACE(REPLACE(c.AffMediaLink,'https://',''),'http://','')AS AffMediaLink
	FROM dbo.AffMediaLink  c WITH (NOLOCK)
	WHERE  AffId =  @AffId AND ChannelCode = @Channelcode
)
-- 1 row
DELETE c
FROM dbo.ClickStatistics c WITH (ROWLOCK)
	INNER JOIN CTE_AffLink ct ON ct.AffMediaLink =  REPLACE(REPLACE(c.AffMediaLink,'https://',''),'http://','')
WHERE  c.AffId = @AffId
PRINT 'Delete AffMediaLink'
-- 2 rows
DELETE c
FROM dbo.AffMediaLink  c WITH (ROWLOCK)
WHERE  AffId =  @AffId AND ChannelCode = @Channelcode
-- 1row
PRINT 'Delete AffMediaChannel'
DELETE c
FROM dbo.AffMediaChannel c WITH (ROWLOCK) 
WHERE AffId = @AffId AND ChannelCode = @Channelcode

GO