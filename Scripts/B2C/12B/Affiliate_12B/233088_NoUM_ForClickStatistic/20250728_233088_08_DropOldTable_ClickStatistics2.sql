/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250730@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Step 8 - Drop ClickStatistics3 after migration [RedmineID: #233088]
*/

IF OBJECT_ID('ClickStatistics3', 'U') IS NOT NULL
    DROP TABLE ClickStatistics3;
