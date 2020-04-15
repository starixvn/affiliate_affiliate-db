USE Affiliate_12BET
GO

/*
	Created: 20200301@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Banners - Rename unused tables
*/

EXEC sp_rename 'Banners_1', 'DEL_Banners_1'
GO

EXEC sp_rename 'BannerTypes_1', 'DEL_BannerTypes_1'
GO