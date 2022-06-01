/*<info serverAlias="DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet"></info>*/
/*
	Created: 20220601@Malcolm
	DB: DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet
	Task: Insert new product

*/
INSERT INTO Product 
(
	ProductName
	,API_ProductID
	,Creator
	,CreatedDate
	,Description
	,BettypeList
	,QMTurnOver
	,QMDeposit
	,ReportColumns
	,EffectiveDate
	,IsEnabled
	,API_Sporttype
	,CreatorName
)
VALUES 
(
	'Bitcoin' -- ProductName
	,69 -- API_ProductID
	,NULL -- Creator
	,GETDATE() -- CreatedDate
	,NULL-- Description
	,NULL -- BettypeList
	,NULL -- QMTurnOver
	,NULL -- QMDeposit
	,NULL -- ReportColumns
	,'2022-06-01' -- EffectiveDate
	,1 -- IsEnabled
	,NULL -- API_Sporttype
	,NULL -- CreatorName
)