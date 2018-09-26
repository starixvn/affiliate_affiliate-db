/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_Bettrans_Sel]
(
	@AffIds		VARCHAR(MAX),
	@FromDate	SMALLDATETIME,
	@ToDate		SMALLDATETIME,
	@ProductIds	VARCHAR(MAX)
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get data of aff's member on bettrans

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	WITH CTE_recommend AS
	(
		SELECT DISTINCT recommend FROM Affiliate_12BET.dbo.MemberInfo WITH (NOLOCK)
		WHERE (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%' + CONVERT(VARCHAR(20), AffId) + '%')
	)
	SELECT
		a.winlostdate,
		mi.AffId,
		a.IBCCustId,
		a.currency,
		a.ProductId,
		a.Deposit,
		a.Withdrawal,
		a.Bonus,
		a.Adjustment,
		a.Turnover,
		a.Winloss
	FROM
	(
		SELECT
			b.winlostdate,
			b.custid AS IBCCustId,
			b.currency,
			CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END AS ProductId,
			SUM(CASE WHEN bt.ProductId = -1 THEN b.winlost-b.actual_stake ELSE 0 END) AS Deposit,
			SUM(CASE WHEN bt.ProductId = -2 THEN -(b.winlost-b.actual_stake) ELSE 0 END) AS Withdrawal,
			SUM(CASE WHEN bt.ProductId = -3 THEN b.winlost-b.actual_stake ELSE 0 END) AS Bonus,
			SUM(CASE WHEN bt.ProductId = -4 THEN b.winlost-b.actual_stake ELSE 0 END) AS Adjustment,
			SUM(CASE WHEN bt.ProductId > 0 AND bt.BetType <> 911 THEN b.stake ELSE 0 END) AS Turnover,
			SUM(CASE WHEN bt.ProductId > 0 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS Winloss
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.Aff_f_ProductBettype_Sel(@ProductIds) bt ON b.bettype = bt.Bettype
			CROSS APPLY CTE_recommend r
		WHERE
			b.recommend = r.recommend
			AND b.statusID NOT IN (0, 1, 101, 102, 103)
		GROUP BY
			b.winlostdate,
			b.custid,
			b.currency,
			CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END
	) AS a
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = a.IBCCustId
	WHERE a.winlostdate BETWEEN @FromDate AND @ToDate
		AND (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%' + CONVERT(VARCHAR(20), AffId) + '%')
GO