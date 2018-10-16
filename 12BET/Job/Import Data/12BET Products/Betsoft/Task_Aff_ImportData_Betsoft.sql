/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_Betsoft]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Betsoft - Get data of aff's member

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblrecommend TABLE (recommend INT PRIMARY KEY)
	
	INSERT INTO @tblrecommend (recommend)
	SELECT DISTINCT recommend FROM dbo.MemberInfo WITH (NOLOCK)

	CREATE TABLE #tempData
	(
		AffId		INT,
		IBCCustId	INT,
		Currency	INT,
		Turnover	MONEY,
		Winloss		MONEY
	)

	INSERT INTO #tempData
	(
		AffId,
		IBCCustId,
		Currency,
		Turnover,
		Winloss
	)
	SELECT
		mi.AffId,
		a.IBCCustId,
		a.currency,
		a.Turnover,
		a.Winloss
	FROM
	(
		SELECT
			b.custid AS IBCCustId,
			b.currency,
			SUM(ISNULL(b.stake, 0)) AS Turnover,
			SUM(ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)) AS Winloss
		FROM bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH (NOLOCK)
			INNER JOIN @tblrecommend r ON b.recommend = r.recommend
		WHERE
			b.WinlostDate = @WinlostDate
			AND b.statusID IN (111, 112, 113)
		GROUP BY
			b.custid,
			b.currency
	) AS a
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = a.IBCCustId
	WHERE NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
				AND mi.IBCCustId = mr.IBCCustId
		)

	MERGE dbo.rptMemberDaily AS TARGET
	USING
		(
			SELECT AffId,IBCCustId,Turnover,Winloss,Currency,e.ActualRate AS ExRate,e.ActualRate2 AS AffExRate
			FROM #tempData d
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(d.Currency, @WinlostDate) e
		) AS SOURCE
		ON		TARGET.WinlostDate	= @WinlostDate
			AND TARGET.ProductId	= 9
			AND TARGET.AffId		= SOURCE.AffId
			AND TARGET.IBCCustId	= SOURCE.IBCCustId
	WHEN MATCHED THEN UPDATE
		SET TARGET.Deposit			= 0,
			TARGET.Withdrawal		= 0,
			TARGET.Bonus			= 0,
			TARGET.Adjustment		= 0,
			TARGET.Turnover			= SOURCE.Turnover,
			TARGET.Winloss			= SOURCE.Winloss
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
		(
			WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate
		)
		VALUES
		(
			@WinlostDate,AffId,IBCCustId,9,0,0,0,0,Turnover,Winloss,Currency,ExRate,AffExRate
		)
	WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @WinlostDate AND TARGET.ProductId = 9 THEN DELETE;

	DROP TABLE #tempData
END
GO