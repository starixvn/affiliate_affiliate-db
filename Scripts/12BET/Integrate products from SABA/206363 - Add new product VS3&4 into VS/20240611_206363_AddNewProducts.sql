/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240611@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new Product VS3 and VS4 [RedmineId : #206363]

*/
INSERT INTO Products([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (43, 'Virtual Sports 3', 'LG', 1, 0, 1, 0, NULL, GETDATE())
      ,(44, 'Virtual Sports 4', 'VS4', 1, 0, 1, 0, NULL, GETDATE())
GO