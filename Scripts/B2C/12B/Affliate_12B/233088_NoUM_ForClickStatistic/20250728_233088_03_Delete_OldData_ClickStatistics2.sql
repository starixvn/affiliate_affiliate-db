/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Delete data from ClickStatistics2 where Date < 2025-08-01 [RedmineID: #233088]
*/

DELETE FROM ClickStatistics2 WITH (ROWLOCK, UPDLOCK)
WHERE [Date] < '20250801';
