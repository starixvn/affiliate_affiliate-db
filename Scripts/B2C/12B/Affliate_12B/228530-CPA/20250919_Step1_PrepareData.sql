/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250919@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Reproduct CPA 15-07 [RedmineID: #239263]
*/

/*
CommGroup
CPAGroupSetting
DealBillingSchedule
AffInfo
AffGroupHistory
*/

USE Affiliate_12B

DECLARE @StartDate DATE = '2025-07-15'
		,@ToDate DATETIME = '9999-12-31'
		,@NextBillingDate DATETIME = '2025-08-04'

--CommGroup
UPDATE CommGroup WITH (ROWLOCK,UPDLOCK)
SET StartDate = @StartDate
WHERE GroupId IN (58,59)

--CPAGroupSetting
UPDATE CPAGroupSetting WITH (ROWLOCK,UPDLOCK)
SET StartDate = @StartDate
WHERE GroupId IN (58,59) AND ToDate = @ToDate

--DealBillingSchedule
UPDATE DealBillingSchedule WITH (ROWLOCK,UPDLOCK)
SET NextBillingDate = @NextBillingDate
WHERE GroupId IN (58,59)

--AffInfo
--92043851
UPDATE AffInfo WITH (ROWLOCK,UPDLOCK)
SET GroupId = 58
WHERE AffId = 92043851

--92043853
UPDATE AffInfo WITH (ROWLOCK,UPDLOCK)
SET GroupId = 59
WHERE AffId = 92043853


--AffGroupHistory
--92043851
UPDATE AffGroupHistory WITH (ROWLOCK,UPDLOCK)
SET GroupId = 58
WHERE AffId = 92043851

--92043853
UPDATE AffGroupHistory WITH (ROWLOCK,UPDLOCK)
SET GroupId = 59
WHERE AffId = 92043853