/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: rptMemberDaily.BetCount [RedmineID: #237540]
*/

USE Affiliate_12B

-- Add BetCount column to rptMemberDaily table
ALTER TABLE rptMemberDaily
ADD BetCount INT NULL;
GO