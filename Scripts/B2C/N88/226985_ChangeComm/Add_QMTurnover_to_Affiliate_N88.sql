/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250514@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: add QMTurnover column [RedmineID: #226985]

*/

-- Script to add QMTurnover column to CommGroup and CommGroupHistory in Affiliate_N88

ALTER TABLE CommGroup
ADD QMTurnover money NULL CONSTRAINT DF_CommGroup_QMTurnover DEFAULT (0);
GO

ALTER TABLE CommGroupHistory
ADD QMTurnover money NULL CONSTRAINT DF_CommGroupHistory_QMTurnover DEFAULT (0);
GO

-- Initialize QMTurnover values to 0 for all existing rows
UPDATE CommGroup WITH (UPDLOCK, ROWLOCK) SET QMTurnover = 0;
GO

UPDATE CommGroupHistory WITH (UPDLOCK, ROWLOCK) SET QMTurnover = 0;
GO

-- Add MinQM and MaxQM columns to TierSetting and TierSettingHistory
ALTER TABLE TierSetting
ADD MinQM int NULL, MaxQM int NULL;
GO

ALTER TABLE TierSettingHistory
ADD MinQM int NULL, MaxQM int NULL;
GO

-- Initialize MinQM and MaxQM values to 0 for all existing rows
UPDATE TierSetting WITH (UPDLOCK, ROWLOCK) SET MinQM = MinAM;
GO
UPDATE TierSetting WITH (UPDLOCK, ROWLOCK) SET MaxQM = MaxAM;
GO
UPDATE TierSettingHistory WITH (UPDLOCK, ROWLOCK) SET MinQM = MinAM;
GO
UPDATE TierSettingHistory WITH (UPDLOCK, ROWLOCK) SET MaxQM = MaxAM;
GO
