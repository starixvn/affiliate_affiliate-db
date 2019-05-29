USE [Affiliate_12BET]
GO

/*
	Created: 20190522@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: AffInfo - New column for Login Info
*/

ALTER TABLE [dbo].[AffInfo]
  ADD SecretKey VARCHAR(50) NULL