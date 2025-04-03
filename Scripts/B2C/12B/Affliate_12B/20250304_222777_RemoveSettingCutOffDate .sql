/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250403@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Remove Setting [RedmineID: #222777]

*/

USE Affiliate_12B
GO

DELETE SystemSettings WHERE SName ='ReportMarketingStatistics_CutOffDate'