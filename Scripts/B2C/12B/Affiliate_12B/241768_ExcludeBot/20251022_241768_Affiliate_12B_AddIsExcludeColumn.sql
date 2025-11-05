/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251022@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Add IsExcluded column to ClickStatistics tables and create ClickStatistics_ExcludePatterns table [RedmineId: #241768]
*/

USE Affiliate_12B
GO

-- Add IsExcluded column to ClickStatistics table
IF NOT EXISTS (SELECT TOP 1 1  FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ClickStatistics') AND name = 'IsExcluded')
BEGIN
    ALTER TABLE dbo.ClickStatistics
    ADD IsExcluded BIT NOT NULL CONSTRAINT DF_ClickStatistics_IsExcluded DEFAULT(0);
END
GO

-- Add IsExcluded column to ClickStatistics_BK table
IF NOT EXISTS (SELECT TOP 1 1  FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ClickStatistics_BK') AND name = 'IsExcluded')
BEGIN
    ALTER TABLE dbo.ClickStatistics_BK
    ADD IsExcluded BIT NOT NULL CONSTRAINT DF_ClickStatistics_BK_IsExcluded DEFAULT(0);
END
GO
 
 