/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210332@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Create Index
*/
DROP INDEX [CIX_LogActionId_LogDate] ON dbo.UserLog_RunSP_Detail

CREATE CLUSTERED INDEX [CIX_LogDate_LogActionId] ON dbo.UserLog_RunSP_Detail 
(
	LogDate ASC, 
	LogActionId ASC
) ON [UserLogData]