USE Affiliate_12BET
GO

/*
	Created: 20200320@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Change data type of FileName: varchar to nvarchar
*/

ALTER TABLE dbo.Banners
	ALTER COLUMN FileName NVARCHAR(200) NOT NULL
GO