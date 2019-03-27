USE [Affiliate_12BET]
GO

/*
	Created: 20190322@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Check all xml data is processed
*/

SELECT COUNT(1)
FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
WHERE FinishedTime IS NULL