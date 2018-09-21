USE [Affiliate_12BET]
GO

/*
	Created: 20180921@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new columns for monthly data
*/

ALTER TABLE dbo.AffCommission
	ADD MemberWithdrawal	MONEY NULL,
		ActivePlayer		INT NULL
GO