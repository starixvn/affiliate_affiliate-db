USE [Affiliate_12BET]
GO

/*
	Created: 20190128@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add 2 new columns: StartDate, EndDate
*/

ALTER TABLE dbo.bettrans_Betsoft
	ADD StartDate	DATETIME NULL,
		EndDate		DATETIME NULL