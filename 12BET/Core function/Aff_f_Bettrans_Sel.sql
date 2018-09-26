/*<info serverAlias="DBEXT-bodb02" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [bodb02]
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
	,CTE_SportBettypeMatrix AS
	(
		SELECT DISTINCT aff.ProductId, bt.BetType
		FROM dbo.SportBettypeMatrix bt WITH (NOLOCK)
			INNER JOIN dbo.Products p WITH (NOLOCK) ON bt.ProductId = p.ProductId
			INNER JOIN Affiliate_12BET.dbo.Products aff WITH (NOLOCK) ON p.ProductPrefix = aff.ProductPrefix
		WHERE bt.bettype NOT IN (911, 912, 913, 914) -- Exclude CashOut (keep 911)
			AND aff.IsIBC = 1
			AND aff.Enabled = 1

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
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN CTE_SportBettypeMatrix bt WITH (NOLOCK) ON b.bettype = bt.Bettype
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
		INNER JOIN Affiliate_12BET.dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = a.IBCCustId
	WHERE (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%' + CONVERT(VARCHAR(20), AffId) + '%')
		AND a.winlostdate BETWEEN @FromDate AND @ToDate
		AND (@ProductIds = '0' OR a.ProductId < 0 OR ',' + @ProductIds + ',' LIKE '%' + CONVERT(VARCHAR(20), a.ProductId) + '%')
GO