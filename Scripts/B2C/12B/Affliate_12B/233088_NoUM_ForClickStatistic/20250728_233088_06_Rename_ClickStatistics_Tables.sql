/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Rename ClickStatistics to ClickStatistics3, ClickStatistics2 to ClickStatistics [RedmineID: #233088]
*/

IF OBJECT_ID('ClickStatistics3', 'U') IS NOT NULL
    DROP TABLE ClickStatistics3;
GO
-- Rename constraints and indexes on ClickStatistics to use ClickStatistics3 prefix before renaming table


-- Rename constraints and indexes on ClickStatistics to use ClickStatistics3 prefix before renaming table
EXEC sp_rename 'PK_ClickStatistics', 'PK_ClickStatistics3';
EXEC sp_rename 'dbo.ClickStatistics.CIX_AffId_Date', 'CIX_ClickStatistics3_AffId_Date';
EXEC sp_rename 'DF_ClickStatistics_Status', 'DF_ClickStatistics3_Status';
EXEC sp_rename 'DF_ClickStatistics_DeviceType', 'DF_ClickStatistics3_DeviceType';
EXEC sp_rename 'DF_ClickStatistics_ClickID2', 'DF_ClickStatistics3_ClickID2';

EXEC sp_rename 'ClickStatistics', 'ClickStatistics3';
GO


-- Rename constraints and indexes to match new table name


-- Rename constraints and indexes on ClickStatistics2 to match ClickStatistics after renaming
EXEC sp_rename 'PK_ClickStatistics2', 'PK_ClickStatistics';
EXEC sp_rename 'dbo.ClickStatistics2.CIX_ClickStatistics2_AffId_Date', 'CIX_ClickStatistics_AffId_Date';
EXEC sp_rename 'DF_ClickStatistics2_Status', 'DF_ClickStatistics_Status';
EXEC sp_rename 'DF_ClickStatistics2_DeviceType', 'DF_ClickStatistics_DeviceType';

EXEC sp_rename 'ClickStatistics2', 'ClickStatistics';
GO