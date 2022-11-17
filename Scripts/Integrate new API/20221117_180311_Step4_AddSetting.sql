/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/

INSERT INTO APIProductSettings (ProductId, SettingName, SettingValue)
VALUES 
	(3, 'LastQueueId', '0')
	,(3, 'LaunchDate', '2022-12-01')
	,(3, 'SourceTable', 'APIProduct_ImportQueue')
	,(3, 'TimeZone', '8')
    ,(3, 'TicketStatus', '')
    ,(10, 'TicketStatus', '')
	,(10, 'TimeZone', '8')

