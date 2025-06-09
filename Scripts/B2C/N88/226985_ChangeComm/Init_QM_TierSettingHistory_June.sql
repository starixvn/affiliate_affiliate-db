/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250605@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: 
		- ReCalculate monthly commission 
	USE Affiliate_N88
	GO
	USE Affiliate_N8B
	GO
	USE Affiliate_N8G
	GO
*/ 
-- Initialize MinQM and MaxQM values to 0 for all existing rows


DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = '2025-06-30'

INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId,TierId,MonthDate,MinAmount,MaxAmount,MinAM,MaxAM,Commission,IsActivePlayerSum,MinQM,MaxQM)
SELECT GroupId,GroupProductId,TierId,'2025-06-30',MinAmount,MaxAmount,MinAM,MaxAM,Commission,IsActivePlayerSum,MinQM,MaxQM
FROM dbo.TierSetting t WITH (NOLOCK)

GO
