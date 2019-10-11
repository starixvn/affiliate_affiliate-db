/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Create index on APIProduct_ImportQueue [RedmineID: #121795]
*/

USE Affiliate_12BET
GO

CREATE NONCLUSTERED INDEX IX_ProductId_WinlostDate ON dbo.APIProduct_ImportQueue (ProductId, WinlostDate) ON [ReportData]
GO