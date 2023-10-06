/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220609@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task : add new tables

*/

CREATE TABLE dbo.BannerStatistics
(
	ClickId			INT IDENTITY(1, 1)
	,AffId			INT
	,BannerId		INT
	,CopyDate		DATETIME DEFAULT GETDATE()
	,CONSTRAINT [PK_BannerStatistics] PRIMARY KEY NONCLUSTERED
	(
		ClickId
	) ON [Data]
) ON [Data]
GO

CREATE CLUSTERED INDEX CIX_CopyDate_BannerId ON BannerStatistics (CopyDate, BannerId)
GO

CREATE TABLE dbo.BannerStatisticsSum
(
	BannerId	INT
	,CopyDate	DATETIME
	,TotalClick INT
	,CONSTRAINT [PK_BannerStatisticsSum] PRIMARY KEY CLUSTERED
	(
		CopyDate, BannerId 
	) ON [Data]
) ON [Data]
GO

CREATE TABLE dbo.BannerStatistics_bk
(
	ClickId		INT
	,AffId		INT
	,BannerId	INT
	,CopyDate	DATETIME 
) ON [Data]
GO

CREATE CLUSTERED INDEX CIX_CopyDate ON BannerStatistics_bk (CopyDate)
GO
