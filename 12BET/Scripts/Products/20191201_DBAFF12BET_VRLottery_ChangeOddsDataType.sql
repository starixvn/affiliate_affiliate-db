USE Affiliate_12BET
GO

/*
	Created: 20200109@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: VR Lottery - API - Change data type of Odds from MONEY to NVARCHAR(100)
*/

ALTER TABLE dbo.bettrans_VRLottery
	ALTER COLUMN Odds NVARCHAR(100)
GO