/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220810@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/


INSERT INTO Market (MarketID, MarketName, MarketNativeName, ShortedCode, DisplayName)
VALUES ('km-KH', 'Cambodian', N'ខ្មែរ', 'km', 'Cambodian')
GO

ALTER TABLE News
ADD Message_Km  NVARCHAR(4000)
GO


