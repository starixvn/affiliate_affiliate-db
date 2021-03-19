/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210312@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update log action
*/

UPDATE l WITH(ROWLOCK)
	SET l.IsShow = 1, l.Description = 'Insert a note'
FROM LogAction l
WHERE L.ActionId = 1015 AND l.ActionTypeId = 11






