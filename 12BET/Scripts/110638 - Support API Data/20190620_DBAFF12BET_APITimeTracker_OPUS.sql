USE Affiliate_12BET
GO

/*
	Created: 20190620@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Re-import data of OPUS due to API's issue
*/

INSERT INTO dbo.APIProduct_TimeTracker (ProductId, CallTime)
SELECT 14, '2019-02-28'