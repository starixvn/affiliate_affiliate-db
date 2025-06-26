/*<info serverAlias="DBAFF12B-Affiliate_12B,DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250624@Lewis
	DB: DBAFF12B-Affiliate_12B,DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Update MaxAmount for TierSetting and TierSettingHistory [RedmineID: #231221]
    
USE Affiliate_12B
GO
USE Affiliate_N88
GO
USE Affiliate_N8B
GO
USE Affiliate_N8G
GO
*/


-- =========================
-- Update MaxAmount for TierSetting and TierSettingHistory
-- =========================

-- Update MaxAmount for TierSetting
SELECT * 
INTO #tempTierSetting
FROM (
    SELECT *, LEAD(MinAmount) OVER (PARTITION BY GroupId, GroupProductId ORDER BY TierId) AS NextMinAmount
    FROM TierSetting WITH (NOLOCK)
    WHERE GroupId NOT IN (SELECT GroupId FROM CommGroup WITH (NOLOCK) WHERE IsDeleted = 1 OR GroupTypeId IN (3,4))
) a
WHERE a.NextMinAmount IS NOT NULL
ORDER BY GroupId, GroupProductId, TierId, MinAmount

UPDATE t SET t.MaxAmount = a.NextMinAmount
FROM TierSetting t WITH (ROWLOCK, UPDLOCK)
INNER JOIN #tempTierSetting a ON a.GroupId = t.GroupId AND a.GroupProductId = t.GroupProductId AND a.TierId = t.TierId

-- Update MaxAmount for TierSettingHistory
SELECT * 
INTO #tempTierSettingHistory
FROM (
    SELECT *, LEAD(MinAmount) OVER (PARTITION BY MonthDate, GroupId, GroupProductId ORDER BY TierId) AS NextMinAmount
    FROM TierSettingHistory WITH (NOLOCK)
    WHERE GroupId NOT IN (SELECT GroupId FROM CommGroup WITH (NOLOCK) WHERE IsDeleted = 1 OR GroupTypeId IN (3,4))
) a
WHERE a.NextMinAmount IS NOT NULL
ORDER BY MonthDate, GroupId, GroupProductId, TierId, MinAmount

UPDATE t SET t.MaxAmount = a.NextMinAmount
FROM TierSettingHistory t WITH (ROWLOCK, UPDLOCK)
INNER JOIN #tempTierSettingHistory a ON a.MonthDate = t.MonthDate AND a.GroupId = t.GroupId AND a.GroupProductId = t.GroupProductId AND a.TierId = t.TierId

DROP TABLE #tempTierSettingHistory
DROP TABLE #tempTierSetting
-- =========================
