/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20230324@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert currency 'BDT' [RedmineId : #185446]
*/
INSERT INTO dbo.SystemSettings(SName, SValue)
VALUES ('AFF_BalPlayerBDT', '12BETAFFPlayerBDT')
	   ,('AFF_MinPlayerBDT', '100')
GO


INSERT INTO dbo.Exchange(UpdatedTime, ExchangeID, Currency, ActualRate, ActualRate2, Creator, DepositPercent, WithdrawalPercent, BuyingRate, BuyingRate2)
VALUES ('2023-03-28 00:00:00', 97, 'BDT', 0.0426848406044030, 0.00952, '48', 0.02, 0.02, 0.0426736897092112, 0.009803)
GO


INSERT INTO dbo.Exchange_Current(ExchangeID, Currency, ActualRate, ActualRate2, Creator, DepositPercent, WithdrawalPercent, BuyingRate, BuyingRate2)
VALUES (97, 'BDT', 0.0426848406044030, 0.00952, '48', 0.02, 0.02, 0.0426736897092112, 0.009803)
GO