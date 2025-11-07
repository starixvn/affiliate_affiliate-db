/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251001@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: Add IsSubCommRate bit column to CommGroup and CommGroupHistory tables
    RedmineID: #235601
    
    Purpose: Add IsSubCommRate bit column to support commission calculation logic
    Business Context: Enable sub-commission rate tracking for commission group configurations
*/
USE Affiliate_12B;
GO


IF COL_LENGTH('dbo.CommGroup', 'IsSubCommRate') IS NULL
BEGIN
    ALTER TABLE dbo.CommGroup 
    ADD IsSubCommRate BIT NOT NULL CONSTRAINT DF_CommGroup_IsSubCommRate DEFAULT (1);
END
GO

UPDATE dbo.CommGroup
SET IsSubCommRate = 1;
GO

IF COL_LENGTH('dbo.CommGroupHistory', 'IsSubCommRate') IS NULL
BEGIN
    ALTER TABLE dbo.CommGroupHistory 
    ADD IsSubCommRate BIT NOT NULL CONSTRAINT DF_CommGroupHistory_IsSubCommRate DEFAULT (1);
END
GO

UPDATE dbo.CommGroupHistory
SET IsSubCommRate = 1;
GO

IF COL_LENGTH('dbo.CPAGroupSetting', 'IsSubCommRate') IS NULL
BEGIN
    ALTER TABLE dbo.CPAGroupSetting 
    ADD IsSubCommRate BIT NOT NULL CONSTRAINT DF_CPAGroupSetting_IsSubCommRate DEFAULT (1);
END
GO

UPDATE dbo.CPAGroupSetting
SET IsSubCommRate = 1;
GO
