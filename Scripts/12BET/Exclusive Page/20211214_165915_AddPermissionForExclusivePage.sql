/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
*/
INSERT INTO LogType (TypeName, Description)
VALUES ('ExclusivePage', 'Exclusive Page' ),
	   ('ExclusiveAffiliatePage', 'Exclusive - Affiliate Page')

DECLARE @ExclusivePage INT, @ExclusiveAffiliatePage INT

SELECT
	@ExclusivePage = CASE WHEN TypeName = 'ExclusivePage' THEN TypeID ELSE @ExclusivePage END
	,@ExclusiveAffiliatePage = CASE WHEN TypeName = 'ExclusiveAffiliatePage' THEN TypeID ELSE @ExclusiveAffiliatePage END
FROM LogType WITH(NOLOCK)

INSERT INTO LogAction (ActionId, ActionTypeId, SPName, Description, IsShow)
VALUES (1025, @ExclusivePage, 'Aff_Admin_ExclusivePage_Ins', 'Upload Exclusive Page', 1)
,(1026, @ExclusivePage, 'Aff_Admin_ExclusivePage_Upd', 'Update Exclusive Page', 1)
,(1027, @ExclusivePage, 'Aff_Admin_ExclusivePage_Del', 'Remove Exclusive Page', 1)

,(1028, @ExclusiveAffiliatePage, 'Aff_Admin_ExclusiveAffiliate_Ins', 'Assign Exclusive Page To Affiliate', 1)
,(1029, @ExclusiveAffiliatePage, 'Aff_Admin_ExclusiveAffiliate_Del', 'Unassign Exclusive Page To Affiliate', 1)