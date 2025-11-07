/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250930@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: LogAction -- Aff_Admin_PaymentCPA_Adjustment_Ins
	RedmineID: #235601
	
*/

USE Affiliate_12B
GO

INSERT INTO LogAction (ActionId, ActionTypeId, SPName, ActionName, IsInternal, Items)
VALUES
(57, 3, 'Aff_Admin_PaymentCPA_Adjustment_Ins', 'Adjust Payment Schedule CPA', 0, NULL)
