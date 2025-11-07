/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251008@lewis.cao
    DB: DBAFF12B-Affiliate_12B
    Task: Add index for affGroupHistory [RedmineID: #235601]
    
*/


--AffGroupHistory

CREATE NONCLUSTERED INDEX IX_AffGroupHistory_AffId_ToDate
ON dbo.AffGroupHistory (AffId)
INCLUDE (GroupId, ParentAffId, AllParentAffId, MonthDate)
WHERE ToDate = '9999-12-31'
WITH (DROP_EXISTING = ON, ONLINE = ON);
GO

CREATE NONCLUSTERED INDEX IX_AffGroupHistory_MonthDate_AffId
ON dbo.AffGroupHistory (MonthDate, AffId)
INCLUDE (GroupId, ParentAffId, AllParentAffId);