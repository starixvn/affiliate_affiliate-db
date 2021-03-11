/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert LogAction for Newsletter
*/

INSERT INTO LogType (TypeName, Description)
VALUES ('Newsletter', 'Newsletter')

INSERT INTO LogAction (ActionId, ActionTypeId, SPName, Description)
values (1006, 27, 'Aff_Admin_Newsletter_Ins', 'Upload Newsletter')
,(1007, 27, 'Aff_Admin_Newsletter_Upd', 'Update Newsletter')
,(1008, 27, 'Aff_Admin_Newsletter_Del', 'Remove Newsletter')

