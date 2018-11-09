USE [Affiliate_12BET]
GO

/*
	Created: 20181109@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert new log action for update password and set favorite an affiliate
*/

INSERT INTO dbo.LogAction (ActionId,ActionTypeId,SPName,Description)
SELECT 35, 2, 'Aff_Admin_Affiliate_Favorite_Upd', 'Update favorite affiliate' UNION ALL
SELECT 36, 2, 'Aff_Admin_Affiliate_Password_Upd', 'Update affiliate password'