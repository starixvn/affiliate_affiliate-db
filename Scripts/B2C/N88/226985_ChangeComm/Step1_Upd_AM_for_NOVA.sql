/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250605@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: update ActivePlayer for table history [RedmineID: #226985]

	USE Affiliate_N88
	GO
	USE Affiliate_N8B
	GO
	USE Affiliate_N8G
	GO
*/

UPDATE TierSettingHistory WITH (UPDLOCK, ROWLOCK) 
SET MinAM = MinQM, MaxAM = MaxQM
WHERE MonthDate = '2025-05-31 00:00:00.000';
GO