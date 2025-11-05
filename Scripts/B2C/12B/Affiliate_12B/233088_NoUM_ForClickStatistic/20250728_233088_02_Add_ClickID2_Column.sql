/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Add ClickID2 column to ClickStatistics (default 0, not identity) [RedmineID: #233088]
*/

IF COL_LENGTH('ClickStatistics', 'ClickID2') IS NULL
BEGIN
    ALTER TABLE ClickStatistics ADD ClickID2 bigint NOT NULL CONSTRAINT DF_ClickStatistics_ClickID2 DEFAULT 0;
END
