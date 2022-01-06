/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
*/
INSERT INTO LogType (TypeName, Description)
VALUES ('OfferPage', 'Offer Page' ),
	   ('OfferAffiliatePage', 'Offer - Affiliate Page')

DECLARE @OfferPage INT, @OfferAffiliatePage INT

SELECT
	@OfferPage = CASE WHEN TypeName = 'OfferPage' THEN TypeID ELSE @OfferPage END
	,@OfferAffiliatePage = CASE WHEN TypeName = 'OfferAffiliatePage' THEN TypeID ELSE @OfferAffiliatePage END
FROM LogType WITH(NOLOCK)

INSERT INTO LogAction (ActionId, ActionTypeId, SPName, Description, IsShow)
VALUES (1025, @OfferPage, 'Aff_Admin_OfferPage_Ins', 'Upload Offer Page', 0)
,(1026, @OfferPage, 'Aff_Admin_OfferPage_Upd', 'Update Offer Page', 0)
,(1027, @OfferPage, 'Aff_Admin_OfferPage_Del', 'Unassign Offer Page From Affiliate (Remove Page)', 1)

,(1028, @OfferAffiliatePage, 'Aff_Admin_OfferAffiliate_Ins', 'Assign Offer Page To Affiliate', 1)
,(1029, @OfferAffiliatePage, 'Aff_Admin_OfferAffiliate_Del', 'Unassign Offer Page From Affiliate', 1)