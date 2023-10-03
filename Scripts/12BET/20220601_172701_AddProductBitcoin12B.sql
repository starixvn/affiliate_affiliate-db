/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220601@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products

*/

INSERT INTO dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, TransferType, Enabled, IsTest, EndOfSupportDate, ReleasedDate)
VALUES (36, 'Bitcoin', 'BTC', 1, 0, 1, 0, NULL, '2022-06-01')