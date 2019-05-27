USE [Affiliate_12BET]
GO

/*
	Created: 20190522@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Enhance Security Questions - Add new column
*/

ALTER TABLE dbo.AffDetail
	ADD QuestionID TINYINT NULL