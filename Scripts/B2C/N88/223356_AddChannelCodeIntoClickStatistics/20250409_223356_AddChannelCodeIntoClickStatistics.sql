/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250408@Sophia
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Task: Add new column ChannelCode into ClickStatistics, ClickStatistics_BK [RedmineID: #223356]

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/
 
 

ALTER TABLE dbo.ClickStatistics
ADD ChannelCode VARCHAR(50) NULL
GO

ALTER TABLE dbo.ClickStatistics_bk
ADD ChannelCode VARCHAR(50) NULL
 