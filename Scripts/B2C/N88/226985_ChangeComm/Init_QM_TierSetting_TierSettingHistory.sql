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
UPDATE TierSetting WITH (UPDLOCK, ROWLOCK) SET MinQM = MinAM;
GO
UPDATE TierSetting WITH (UPDLOCK, ROWLOCK) SET MaxQM = MaxAM;
GO
UPDATE TierSettingHistory WITH (UPDLOCK, ROWLOCK) SET MinQM = MinAM;
GO
UPDATE TierSettingHistory WITH (UPDLOCK, ROWLOCK) SET MaxQM = MaxAM;
GO
