/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250408@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Add new column ChannelCode into ClickStatistics, ClickStatistics_BK [RedmineID: #222765]
		 

*/

USE [Affiliate_12B]
GO

ALTER TABLE [Affiliate_12B].dbo.ClickStatistics
ADD ChannelCode VARCHAR(50) NULL
GO

ALTER TABLE [Affiliate_12B].dbo.ClickStatistics_bk
ADD ChannelCode VARCHAR(50) NULL
 