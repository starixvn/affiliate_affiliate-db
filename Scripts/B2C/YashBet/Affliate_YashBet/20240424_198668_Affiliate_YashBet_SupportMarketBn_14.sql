/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Support bangladeshi language
	
*/



DELETE m
FROM dbo.Market m 
WHERE m.MarketId = 'hi-IN'
;
INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
	VALUES (N'bn-BD', N'Bangladeshi', N'বাংলাদেশী', N'bn', N'Bangladeshi');
