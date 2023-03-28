/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20230323@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add Bangladesh Language [RedmineId : #185446]
*/
INSERT INTO Market (MarketID, MarketName, MarketNativeName, ShortedCode, DisplayName)
VALUES ('bn-BD', 'English (Bangladesh)', N'English (Bangladesh)', 'bn', 'English (Bangladesh)')
GO

ALTER TABLE dbo.News
ADD Message_Bn NVARCHAR(4000)
GO

ALTER TABLE dbo.Messages
ADD MessageContentBN NVARCHAR(2000)
GO