/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250326@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Add more messages and CutofDate commission [RedmineID: #219936]
	- Remove any unused deductions
*/

USE Affiliate_12B
GO

UPDATE c SET IsDeleted = 1 FROM dbo.Deductions c WITH (ROWLOCK, UPDLOCK) WHERE DeductionId IN (11, 15, 16)
GO
