/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230320@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add setting value for products [RedmineId : #180311]
*/
INSERT INTO dbo.APIProductSettingsTest (ProductId, SettingName, SettingValue)
VALUES (40, 'ExcludeTicketStatus', '')--   					12Zircon BG
	   ,(40, 'LastQueueId', '0')-- 							12Zircon BG
	   ,(40, 'LaunchDate', '2023-03-21')-- 					12Zircon BG
	   ,(40, 'SourceTable', 'APIProduct_ImportQueueTest')--	12Zircon BG
	   ,(40, 'TimeZone', '-4')-- 							12Zircon BG
	   ,(34, 'ExcludeTicketStatus', '')--   				12Jasper N2 Live
	   ,(34, 'LastQueueId', '0')-- 							12Jasper N2 Live
	   ,(34, 'LaunchDate', '2022-06-01')-- 					12Jasper N2 Live
	   ,(34, 'SourceTable', 'APIProduct_ImportQueueTest')-- 12Jasper N2 Live
	   ,(34, 'TimeZone', '-4')-- 							12Jasper N2 Live
	   ,(35, 'ExcludeTicketStatus', '')--   				12Sunstone EA
	   ,(35, 'LastQueueId', '0')-- 							12Sunstone EA
	   ,(35, 'LaunchDate', '2022-06-01')-- 					12Sunstone EA
	   ,(35, 'SourceTable', 'APIProduct_ImportQueueTest')-- 12Sunstone EA
	   ,(35, 'TimeZone', '-4')-- 							12Sunstone EA
	   ,(32, 'ExcludeTicketStatus', '')--   				12Sapphire Skywind
	   ,(32, 'LastQueueId', '0')-- 							12Sapphire Skywind
	   ,(32, 'LaunchDate', '2021-09-01')-- 					12Sapphire Skywind
	   ,(32, 'SourceTable', 'APIProduct_ImportQueueTest')-- 12Sapphire Skywind
	   ,(32, 'TimeZone', '7')-- 							12Sapphire Skywind
	   ,(31, 'ExcludeTicketStatus', '')--   				IM Esports
	   ,(31, 'LastQueueId', '0')-- 							IM Esports
	   ,(31, 'LaunchDate', '2021-07-01')-- 					IM Esports
	   ,(31, 'SourceTable', 'APIProduct_ImportQueueTest')-- IM Esports
	   ,(31, 'TimeZone', '-6')-- 							IM Esports
	   ,(25, 'ExcludeTicketStatus', '')--   				BTi
	   ,(25, 'LastQueueId', '0')-- 							BTi
	   ,(25, 'LaunchDate', '2021-01-01')-- 					BTi
	   ,(25, 'SourceTable', 'APIProduct_ImportQueueTest')-- BTi
	   ,(25, 'TimeZone', '0')-- 							BTi
	   ,(24, 'ExcludeTicketStatus', '')--   				KY Gaming
	   ,(24, 'LastQueueId', '0')-- 							KY Gaming
	   ,(24, 'LaunchDate', '2020-07-01')-- 					KY Gaming
	   ,(24, 'SourceTable', 'APIProduct_ImportQueueTest')-- KY Gaming
	   ,(24, 'TimeZone', '8')-- 							KY Gaming
	   ,(23, 'ExcludeTicketStatus', '')--   				12Topaz
	   ,(23, 'LastQueueId', '0')-- 							12Topaz
	   ,(23, 'LaunchDate', '2020-01-01')-- 					12Topaz
	   ,(23, 'SourceTable', 'APIProduct_ImportQueueTest')-- 12Topaz
	   ,(23, 'TimeZone', '0')-- 							12Topaz
	   ,(21, 'ExcludeTicketStatus', '')--   				VR Lottery
	   ,(21, 'LastQueueId', '0')-- 							VR Lottery
	   ,(21, 'LaunchDate', '2020-01-01')-- 					VR Lottery
	   ,(21, 'SourceTable', 'APIProduct_ImportQueueTest')-- VR Lottery
	   ,(21, 'TimeZone', '8')-- 							VR Lottery
	   ,(11, 'ExcludeTicketStatus', '')--   				12Amber Betsoft
	   ,(11, 'LastQueueId', '0')-- 							12Amber Betsoft
	   ,(11, 'LaunchDate', '2018-12-01')-- 					12Amber Betsoft
	   ,(11, 'SourceTable', 'APIProduct_ImportQueueTest')-- 12Amber Betsoft
	   ,(11, 'TimeZone', '8')-- 							12Amber Betsoft
	   ,(3, 'ExcludeTicketStatus', '')--   				 	12Emerald Playtech
	   ,(3, 'LastQueueId', '0')-- 							12Emerald Playtech
	   ,(3, 'LaunchDate', '2013-01-18')-- 					12Emerald Playtech
	   ,(3, 'SourceTable', 'APIProduct_ImportQueueTest')-- 	12Emerald Playtech
	   ,(3, 'TimeZone', '8')-- 								12Emerald Playtech
GO

INSERT INTO dbo.APIProductMappingSettingsTest (TpType, SubItem, ProductId )
VALUES (24, '', 40)--  12Zircon BG
	   ,(22, '', 34)-- 12Jasper N2 Live
	   ,(21, '', 35)-- 12Sunstone EA
	   ,(17, '', 32)-- 12Sapphire Skywind
	   ,(14, '', 31)-- IM Esports
	   ,(15, '', 25)-- BTi
	   ,(19, '', 24)-- KY Gaming
	   ,(18, '', 23)-- 12Topaz
	   ,(16, '', 21)-- VR Lottery
	   ,(10, '', 11)-- 12Amber Betsoft
	   ,(1, '', 3)--   12Emerald Playtech
GO