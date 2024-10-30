/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20241023@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new Product VS5 and VS6 [RedmineId : #212551]

*/
USE Affiliate_12BET
GO

INSERT INTO Products([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (52, 'Virtual Sports 5', 'VS5', 1, 0, 1, 0, NULL, GETDATE())
      ,(53, 'Virtual Sports 6', 'VS6', 1, 0, 1, 0, NULL, GETDATE())
GO