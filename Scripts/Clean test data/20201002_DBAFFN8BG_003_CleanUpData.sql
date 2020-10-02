/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/

/*
	Created: 20201002@Percy
	DB:
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Clean test data

	Step 3: Clean up data
*/

/*
USE Affiliate_N8B
USE Affiliate_N8G
*/

use Affiliate_N8G
go

delete dbo.AffGroupInfo with (rowlock, updlock)
where GroupId = 1000

delete dbo.AffGroupPolicy with (rowlock, updlock)
where GroupId = 1000

truncate table dbo.CommGroup
truncate table dbo.DeductionSetting
truncate table dbo.DeductionSettingHistory
truncate table dbo.TierSetting
truncate table dbo.TierSettingHistory