/*<info serverAlias="DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet"></info>*/
/*
	Created: 20220511@Malcolm
	DB: DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet
	Task: Update product name

*/

UPDATE Product WITH(ROWLOCK)
	SET IsEnabled = 0
WHERE ProductName IN ('Live Casino', 'Gold Deluxe', 'Macau', 'Racing')

DELETE g WITH(ROWLOCK, UPDLOCK)
FROM GroupSetting g
	INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = g.ProductID
WHERE p.ProductName IN ('Live Casino', 'Gold Deluxe', 'Macau', 'Racing')

DELETE g WITH(ROWLOCK, UPDLOCK)
FROM DeductionSetting g
	INNER JOIN DeductionType dt WITH(NOLOCK) ON dt.DTypeID = g.DeductionID
	INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = dt.ProductID
WHERE p.ProductName IN ('Live Casino', 'Gold Deluxe', 'Macau', 'Racing')


