/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240318@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Delete data in table "DeductionSetting" [RedmineId : #201095]
*/
-- DeductionID = 10: Platform Fee
-- ProductId   = 7 : Virtual Sports 2 (VS2)  >>>> because VS2 is merged into VS
DELETE DeductionSetting
WHERE DeductionID = 10 AND ProductId = 7
GO