/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250827@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Drop table and SP [RedmineID: #233219]
*/
USE Affiliate_12B
GO

-- table
DROP TABLE IF EXISTS DEL_SpecificDomainControl_More
GO
DROP TABLE IF EXISTS DEL_SpecificDomainControl
GO

-- SPs
DROP PROC IF EXISTS DEL_Aff_ClickStatistics_Ins
GO
DROP PROC IF EXISTS DEL_Aff_ClickStatistics_Ins_UAT2
GO
DROP PROC IF EXISTS DEL_Aff_ClickStatistics_Ins_xpre
GO
DROP PROC IF EXISTS DEL_Aff_ClickStatistics_Ins_xtest
GO