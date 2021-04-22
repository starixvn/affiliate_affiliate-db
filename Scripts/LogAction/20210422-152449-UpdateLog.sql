/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
/*
	Created: 20210422@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
*/
UPDATE UserLog_RunSP_Detail WITH(ROWLOCK)
	SET LogActionId = 1021, LogTypeId = 18
WHERE SPName = 'Aff_CustomerInsMember'