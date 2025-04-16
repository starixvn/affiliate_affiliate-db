/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Revisions:
		- 20250415@Sophia: Build version UAT for testing new API [Redmine #223271]
*/
-- Drop the UAT tables
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MemberInfo_UAT]') AND type in (N'U'))
    DROP TABLE [dbo].[MemberInfo_UAT]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CurrencyConverter_UAT]') AND type in (N'U'))
    DROP TABLE [dbo].[CurrencyConverter_UAT]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AffInfo_UAT]') AND type in (N'U'))
    DROP TABLE [dbo].[AffInfo_UAT]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClickStatistics_UAT]') AND type in (N'U'))
    DROP TABLE [dbo].[ClickStatistics_UAT]
GO

PRINT 'All UAT tables have been dropped successfully.'
GO
