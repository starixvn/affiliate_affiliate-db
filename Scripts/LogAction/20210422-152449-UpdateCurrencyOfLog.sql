/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*  
Created: 20210423@Malcolm
Task : Update Currency [RedmineId : #152957]
*/
USE Affiliate_12BET
GO

DECLARE @LogData TABLE (LogId INT)

INSERT INTO @LogData (LogId)
VALUES (114733),(114735),(114738),(114739),(114762),(114763),(114768),(114770),(114782),(114834),(114860),(114875),(114876),(114890)

UPDATE u WITH(ROWLOCK)
	SET u.NewData = REPLACE(u.NewData,'Currency="INH"', 'Currency="VND"' )
FROM UserLog_RunSP_Detail u
WHERE EXISTS (SELECT 1 FROM @LogData l WHERE u.LogId = l.LogId)

