/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250523@Sally
    DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Remove data P2P Setting [RedmineID: #226985]

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/

-- Delete data from dbo.StraightSettingHistory for MonthDate = '2025-06-30'
DELETE FROM dbo.StraightSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate >= '2025-06-30';
GO

-- Delete all data from dbo.StraightSetting
DELETE FROM dbo.StraightSetting WITH (ROWLOCK, UPDLOCK);
GO
