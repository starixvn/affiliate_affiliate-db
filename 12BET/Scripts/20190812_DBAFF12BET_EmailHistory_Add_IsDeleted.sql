USE Affiliate_12BET
GO

/*
	Created: 20190812@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new column for Email
*/

ALTER TABLE dbo.EmailHistory
	ADD IsDeleted BIT NULL
GO

ALTER TABLE [dbo].[EmailHistory] ADD  CONSTRAINT [DF_EmailHistory_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO