USE [Affiliate_12BET]
GO

/*
	Created: 20190529@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Change Keno to RNG Keno
	RedmineID: #114333

	SELECT *
	FROM dbo.Products WITH (NOLOCK)
	WHERE ProductId = 6
*/

UPDATE dbo.Products WITH (ROWLOCK)
SET ProductName = 'RNG Keno'
WHERE ProductId = 6