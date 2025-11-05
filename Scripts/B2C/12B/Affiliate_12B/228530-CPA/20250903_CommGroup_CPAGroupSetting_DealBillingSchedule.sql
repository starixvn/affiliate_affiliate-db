/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: CommGroup, CPAGroupSetting -- Drop column IsInstant 
		  DealBillingSchedule -- add column Type and init data [RedmineID: #237540]
*/

USE Affiliate_12B

-- Drop IsInstant column from CommGroup table
ALTER TABLE CommGroup 
DROP COLUMN IsInstant;
GO
-- Drop IsInstant column from CPAGroupSetting table
ALTER TABLE CPAGroupSetting 
DROP COLUMN IsInstant;
GO
-- Type -- DealBillingSchedule
ALTER TABLE dbo.DealBillingSchedule
ADD [Type] VARCHAR(100) NULL;
GO

ALTER TABLE dbo.DealBillingSchedule
ADD CONSTRAINT DF_DealBillingSchedule_Type 
    DEFAULT ('CPA') FOR [Type];
GO

-- Init data
UPDATE s
SET s.[Type] = 'CPA'
FROM dbo.DealBillingSchedule s WITH (ROWLOCK, UPDLOCK)
GO

-- update deal monthly 4th
UPDATE s
SET s.NextBillingDate = DATEADD(DAY, -1, s.NextBillingDate)
FROM dbo.DealBillingSchedule s WITH (ROWLOCK, UPDLOCK)
WHERE s.ScheduleId = 5
GO