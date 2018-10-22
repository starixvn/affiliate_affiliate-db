/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_AGCasino_CheckData]
	@WinlostDate		SMALLDATETIME,
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get data of aff's member on bettrans_AGCasino

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsMissmatch BIT = 1

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
		AND mi.AffId IN (927841,92040664,92040667) -- testing Affiliates - will remove later

	IF EXISTS (
		SELECT 1
		FROM #tempData d
			FULL OUTER JOIN dbo.rptMemberDaily md WITH (NOLOCK)
				ON		d.AffId			= md.AffId
					AND d.IBCCustId		= md.IBCCustId
					AND md.WinlostDate	= @WinlostDate
					AND md.ProductId	= 9
		WHERE d.AffId IS NULL
			OR md.AffId IS NULL
			OR d.Turnover <> md.Turnover
			OR d.Winloss <> md.Winloss
	)
		SELECT @IsMissmatch = 1
	ELSE
		SELECT @IsMissmatch = 0

	IF @IsCheckDataOnly = 0
	BEGIN
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
		END
	ELSE
	BEGIN
		SELECT
			d.AffId					AS AffId_Source,
			md.AffId				AS AffId_Target,
			d.IBCCustId				AS IBCCustId_Source,
			md.IBCCustId			AS IBCCustId_Target,
			ISNULL(d.Turnover, 0)	AS Turnover_Source,
			ISNULL(md.Turnover, 0)	AS Turnover_Target,
			ISNULL(d.Winloss, 0)	AS Winloss_Source,
			ISNULL(md.Winloss, 0)	AS Winloss_Target
		FROM #tempData d
			FULL OUTER JOIN dbo.rptMemberDaily md WITH (NOLOCK)
				ON		d.AffId			= md.AffId
					AND d.IBCCustId		= md.IBCCustId
					AND md.WinlostDate	= @WinlostDate
					AND md.ProductId	= 9
		WHERE d.AffId IS NULL
			OR md.AffId IS NULL
			OR d.Turnover <> md.Turnover
			OR d.Winloss <> md.Winloss
	END

	DROP TABLE #tempData
END
