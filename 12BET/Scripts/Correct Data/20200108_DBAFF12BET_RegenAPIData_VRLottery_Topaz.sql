USE Affiliate_12BET
GO

/*
	Created: 20200108@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: VRLottery & Topaz - Update FinishedTime to regen API data
*/

-- 9258 rows
UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK)
SET FinishedTime = NULL
WHERE ProductId IN (21, 23)
GO