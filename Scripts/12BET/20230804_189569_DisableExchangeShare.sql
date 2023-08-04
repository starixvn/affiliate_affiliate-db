/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230804@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: 'ExchangeWinlossShare' and 'ExchangeCommShare' out of use [RedmineID: #189569]
*/
UPDATE dbo.Deductions
SET IsDeleted = 1
WHERE DeductionName IN ('Exchange Win Loss Share', 'Exchange Commission Share')
GO