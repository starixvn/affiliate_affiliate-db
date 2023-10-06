/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20230905@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Unlock for fail login
*/

UPDATE u
SET u.FailedLoginCount = 0, u.Closed = 0
FROM Users u WITH (ROWLOCK, UPDLOCK)
WHERE u.CustId IN (10000003, 10000022)
GO