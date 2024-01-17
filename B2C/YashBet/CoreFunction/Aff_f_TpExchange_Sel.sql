/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_TpExchange_Sel]
(	
	@TpExchangeId	INT
)
RETURNS TABLE
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: function - Get TpExchange 

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @TpExchangeId : Currency of B2C

*/
RETURN (
	SELECT ISNULL(n2.ExchangeId, n.TpExchangeId) AS ExchangeId,ISNULL(n2.TpExchangeId, n.TpExchangeId) AS TpExchangeId
	FROM (VALUES (@TpExchangeId)) AS n(TpExchangeId)
	OUTER APPLY (
		SELECT t.ExchangeId 
		FROM dbo.TpExchange t WITH (NOLOCK)
		WHERE t.TpExchangeId = n.TpExchangeId
	) n1(ExchangeId)
	OUTER APPLY (
		SELECT TpExchangeId, ExchangeId
		FROM dbo.TpExchange t WITH (NOLOCK)
		WHERE t.ExchangeId = n1.ExchangeId
	) AS n2
)

	
