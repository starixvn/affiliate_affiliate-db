USE Affiliate_12BET
GO

/*
	Created: 20200301@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Banners - Rename unused SPs
*/

EXEC sp_rename 'Aff_HomeGeneralInfo', 'DEL_Aff_HomeGeneralInfo'
GO
EXEC sp_rename 'Aff_DBAInsBannerType', 'Aff_DBAInsBannerType'
GO
EXEC sp_rename 'Task_STDBY_SYNC_AFF12BET_TableOther', 'Task_STDBY_SYNC_AFF12BET_TableOther'
GO
EXEC sp_rename 'Aff_TextSel', 'Aff_TextSel'
GO
EXEC sp_rename 'Aff_TextSelDetail', 'Aff_TextSelDetail'
GO
EXEC sp_rename 'Aff_TextIns', 'Aff_TextIns'
GO
EXEC sp_rename 'Aff_TextUpd', 'Aff_TextUpd'
GO
EXEC sp_rename 'Aff_TextDel', 'Aff_TextDel'
GO
EXEC sp_rename 'Aff_BannerDel_1', 'Aff_BannerDel_1'
GO
EXEC sp_rename 'Aff_BannerDelType_1', 'Aff_BannerDelType_1'
GO
EXEC sp_rename 'Aff_BannerMediaIns', 'Aff_BannerMediaIns'
GO
EXEC sp_rename 'Aff_BannerInsType_1', 'Aff_BannerInsType_1'
GO
EXEC sp_rename 'Aff_BannerSel_1', 'Aff_BannerSel_1'
GO
EXEC sp_rename 'Aff_BannerSelByParentCate', 'Aff_BannerSelByParentCate'
GO
EXEC sp_rename 'Aff_BannerSelDetail_1', 'Aff_BannerSelDetail_1'
GO
EXEC sp_rename 'Aff_BannerSelType_1', 'Aff_BannerSelType_1'
GO
EXEC sp_rename 'Aff_BannerUpd_1', 'Aff_BannerUpd_1'
GO
EXEC sp_rename 'Aff_TextSel_1', 'Aff_TextSel_1'
GO
EXEC sp_rename 'Aff_TextSelDetail_1', 'Aff_TextSelDetail_1'
GO
EXEC sp_rename 'Aff_TextIns_1', 'Aff_TextIns_1'
GO
EXEC sp_rename 'Aff_TextUpd_1', 'Aff_TextUpd_1'
GO
EXEC sp_rename 'Aff_BannerDel', 'Aff_BannerDel'
GO
EXEC sp_rename 'Aff_TextDel_1', 'Aff_TextDel_1'
GO
EXEC sp_rename 'Aff_BannerDelType', 'Aff_BannerDelType'
GO
EXEC sp_rename 'Aff_BannerIns', 'Aff_BannerIns'
GO
EXEC sp_rename 'Aff_BannerInsType', 'Aff_BannerInsType'
GO
EXEC sp_rename 'Aff_BannerSel', 'Aff_BannerSel'
GO
EXEC sp_rename 'Aff_BannerIns_1', 'Aff_BannerIns_1'
GO
EXEC sp_rename 'Aff_BannerSelDetail', 'Aff_BannerSelDetail'
GO
EXEC sp_rename 'Aff_BannerSelType', 'Aff_BannerSelType'
GO
EXEC sp_rename 'Aff_BannerUpd', 'Aff_BannerUpd'
GO