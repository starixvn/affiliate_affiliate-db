USE [Affiliate_12BET]
GO

/*
	Created: 20190520@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new column on bettrans_Ebet: CreateDate
*/

ALTER TABLE dbo.bettrans_Ebet
	ADD CreateTime DATETIME NULL
GO