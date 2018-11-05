INSERT INTO dbo.LogAction (ActionId,ActionTypeId,SPName,Description)
SELECT 35, 2, 'Aff_Admin_Affiliate_Favorite_Upd', 'Update favorite affiliate' UNION ALL
SELECT 36, 2, 'Aff_Admin_Affiliate_Password_Upd', 'Update affiliate password'