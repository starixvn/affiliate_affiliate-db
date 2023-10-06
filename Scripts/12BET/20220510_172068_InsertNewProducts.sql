/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20220511@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: insert new settings
*/

INSERT INTO Products (ProductId, ProductName, ProductPrefix, IsIBC, TransferType, Enabled, IsTest, EndOfSupportDate, ReleasedDate)
VALUES (34, '12Jasper - N2 Live', 'N2', 0, 0, 1, 0, NULL, NULL)
	,(35, '12Sunstone - EA', 'EA', 0, 0, 1, 0, NULL, NULL)


INSERT INTO APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (34, 'LastQueueId', '0')
		,(34, 'LaunchDate', '2022-06-01')
		,(34, 'SourceTable', 'APIProduct_ImportQueue')
		,(35, 'LastQueueId', '0')
		,(35, 'LaunchDate', '2022-06-01')
		,(35, 'SourceTable', 'APIProduct_ImportQueue')