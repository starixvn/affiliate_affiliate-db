/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251111@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Reproduct CPA 15-07 [RedmineID: #242980]
*/

/*
DealBillingSchedule
AffTrans
CPAJobLog
*/

USE Affiliate_12B

DECLARE @StartDate DATE = '2025-07-15'

--DealBillingSchedule --2 rows affected
UPDATE DealBillingSchedule WITH (ROWLOCK,UPDLOCK)
SET NextBillingDate = DATEADD(DAY, 29, @StartDate)
WHERE GroupId IN (58,59)


--AffTrans --4 rows affected
DELETE AffTrans WITH (ROWLOCK)
WHERE AffId IN  (92043851,92043853) AND TransType = 206


--CPAJobLog --732 rows affected
DELETE CPAJobLog WITH (ROWLOCK)
