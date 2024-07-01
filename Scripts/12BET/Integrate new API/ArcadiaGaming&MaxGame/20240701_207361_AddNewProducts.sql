/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240701@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new Product CC and MXG [RedmineId : #207119]

*/
INSERT INTO Products([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (45, 'Arcadia Gaming', 'CC', 1, 0, 1, 0, NULL, GETDATE())
      ,(46, 'MaxGame', 'MXG', 1, 0,	1,	0, NULL, GETDATE())
GO