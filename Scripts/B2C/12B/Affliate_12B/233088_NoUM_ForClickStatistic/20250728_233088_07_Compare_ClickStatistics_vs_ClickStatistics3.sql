/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Compare ClickStatistics (new) vs ClickStatistics3 (old) [RedmineID: #233088]
*/

-- Compare row counts
SELECT 'ClickStatistics' AS TableName, COUNT_BIG(*) [RowCount] FROM ClickStatistics
UNION ALL
SELECT 'ClickStatistics3', COUNT_BIG(*) FROM ClickStatistics3;

-- Compare data differences (example: ClickId)
SELECT a.ClickId AS ClickId_New, b.ClickId AS ClickId_Old
FROM ClickStatistics a
FULL OUTER JOIN ClickStatistics3 b ON a.ClickId = b.ClickId
WHERE a.ClickId IS NULL OR b.ClickId IS NULL;
