/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250811@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Delete SP [RedmineID: #233219]
*/
USE Affiliate_12B
GO

/*
-- SP and its version need to be deleted
SELECT name
FROM sys.objects
WHERE name LIKE '%Aff_ClickStatistics_Ins%'
*/

EXEC sp_rename 'Aff_ClickStatistics_Ins', 'DEL_Aff_ClickStatistics_Ins'
GO
EXEC sp_rename 'Aff_ClickStatistics_Ins_UAT2', 'DEL_Aff_ClickStatistics_Ins_UAT2'
GO
EXEC sp_rename 'Aff_ClickStatistics_Ins_xpre', 'DEL_Aff_ClickStatistics_Ins_xpre'
GO
EXEC sp_rename 'Aff_ClickStatistics_Ins_xtest', 'DEL_Aff_ClickStatistics_Ins_xtest'
GO