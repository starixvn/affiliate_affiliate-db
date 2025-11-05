/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251030@Sally.Ton
    DB: DBAFF12B.Affiliate_12B
    Task: rptMemberDaily.DepositCount [RedmineID: #242833]
*/

USE Affiliate_12B
GO
-- Add DepositCount column to rptMemberDaily table
ALTER TABLE rptMemberDaily
ADD DepositCount INT NULL;
GO