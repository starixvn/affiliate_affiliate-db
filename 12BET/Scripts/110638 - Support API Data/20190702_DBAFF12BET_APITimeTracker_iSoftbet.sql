USE Affiliate_12BET
GO

/*
	Created: 20190702@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: 12BET - Support web re-pull API data of iSoftbet from Jun 2019
*/

INSERT INTO dbo.APIProduct_TimeTracker (ProductId, CallTime)
SELECT 13, '2019-05-31'
GO