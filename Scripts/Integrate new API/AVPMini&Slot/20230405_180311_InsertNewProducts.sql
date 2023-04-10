/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230405@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO Products (ProductId , ProductName, ProductPrefix , IsIBC , TransferType, Enabled, IsTest, EndOfSupportDate, ReleasedDate)
VALUES (41, '12Garnet - AVP Mini', '12AVPM', 0, 0, 1, 0, NULL, NULL)
	 , (42, '12Garnet - AVP Slot', '12AVPS', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (41, 'ExcludeTicketStatus', '')-- AVP Mini
	   ,(41, 'LastQueueId', '0')					
	   ,(41, 'LaunchDate', '2023-04-01')				
	   ,(41, 'SourceTable', 'APIProduct_ImportQueue')
	   ,(41, 'TimeZone', '8')					
	   ,(42, 'ExcludeTicketStatus', '')-- AVP Slot
	   ,(42, 'LastQueueId', '0')
	   ,(42, 'LaunchDate', '2023-04-01')
	   ,(42, 'SourceTable', 'APIProduct_ImportQueue')
	   ,(42, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId )
VALUES (25, '', 41)--  AVP Mini
	   ,(26, '', 42)-- AVP Slot
GO