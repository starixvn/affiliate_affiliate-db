/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210312@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update log action
*/

UPDATE l WITH(ROWLOCK)
	SET l.IsShow = 1, l.Description = 'Admin updates affiliate status'
FROM LogAction l
WHERE L.SPName in ('Aff_Admin_Affiliate_Approved', 'Aff_Admin_AffiliateStatus_Upd')







