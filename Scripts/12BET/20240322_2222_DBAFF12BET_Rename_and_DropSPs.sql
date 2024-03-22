/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240322@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Rename and Drop unused SPs

*/
-- Rename SPs 
EXEC sp_rename 'Aff_AffiliateStatistics', 'DEL_Aff_AffiliateStatistics'
GO
EXEC sp_rename 'Aff_AffiliateStatisticsDetail', 'DEL_Aff_AffiliateStatisticsDetail'
GO
EXEC sp_rename 'Aff_ActiveMemberReport', 'DEL_Aff_ActiveMemberReport'
GO
EXEC sp_rename 'Aff_DEP_MemberListSel', 'DEL_Aff_DEP_MemberListSel'
GO
EXEC sp_rename 'Aff_StatisticsSel', 'DEL_Aff_StatisticsSel'
GO
EXEC sp_rename 'Aff_User_StatisticsSel', 'DEL_Aff_User_StatisticsSel'
GO

-- Drop SPs 
DROP PROCEDURE DEL_Aff_AffiliateStatistics
GO
DROP PROCEDURE DEL_Aff_AffiliateStatisticsDetail
GO
DROP PROCEDURE DEL_Aff_ActiveMemberReport
GO
DROP PROCEDURE DEL_Aff_DEP_MemberListSel
GO
DROP PROCEDURE DEL_Aff_StatisticsSel
GO
DROP PROCEDURE DEL_Aff_User_StatisticsSel
GO