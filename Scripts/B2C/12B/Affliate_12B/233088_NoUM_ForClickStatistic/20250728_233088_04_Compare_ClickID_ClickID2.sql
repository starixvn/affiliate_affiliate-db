/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Compare ClickStatistics.ClickId vs ClickStatistics.ClickID2 [RedmineID: #233088]
*/

SELECT ClickId, ClickID2
FROM ClickStatistics WITH (NOLOCK)
WHERE ClickId <> ClickID2;
