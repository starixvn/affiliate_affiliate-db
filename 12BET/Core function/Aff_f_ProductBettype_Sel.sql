/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_ProductBettype_Sel]
(
	@ProductIds VARCHAR(MAX)
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get Product - Bettype relationship

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	SELECT DISTINCT p.ProductId, s.BetType
	FROM dbo.Products p WITH (NOLOCK)
		INNER JOIN bodb02.dbo.f_SportBettypeMatrix_Sel(0,0,0,2,'','',1) s ON p.ProductPrefix = s.ProductPrefix
	WHERE p.IsIBC = 1
		AND p.Enabled = 1
		AND (@ProductIds = '0' OR ',' + @ProductIds + ',' LIKE '%' + CONVERT(VARCHAR(20), p.ProductId) + '%')

	UNION ALL
	SELECT 1, 911 WHERE (@ProductIds = '0' OR ',' + @ProductIds + ',' LIKE '%1%')

	UNION ALL -- transfer
	SELECT bt.ProductId, bt.Bettype
	FROM (
		VALUES
			-- -1: Deposit
			(-1, 22001),
			-- -2: Withdrawal
			(-2, 22002), (-2, 22003),
			-- -3: Bonus
			(-3, 22004), (-3, 22200),
			-- -4: Adjustment
			(-4, 21001), (-4, 21002), (-4, 21003), (-4, 21004), (-4, 21005),
			(-4, 22005), (-4, 22201)
	) AS bt (ProductId, Bettype)
GO