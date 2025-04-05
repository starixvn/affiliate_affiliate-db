/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250403@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: OT_Add cutoff date for ClickId [RedmineID: #222929]

*/

USE Affiliate_12B
GO
 
 
 INSERT INTO SystemSettings (SName, SValue)
 VALUES ('MKTStatisticsRpt_ClickId_CutOffDate', '2025-03-31 00:00:00')