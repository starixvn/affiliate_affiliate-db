/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_3rdProduct_CheckData]
	@ProductId			INT,
	@WinlostDate		SMALLDATETIME,
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Check data of aff's member - 3rd Products

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20190117@Percy: Add Gold Deluxe [RedmineID: #106503]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsMismatch BIT = 1

	DECLARE @tblrecommend TABLE (recommend INT PRIMARY KEY)
	
	INSERT INTO @tblrecommend (recommend)
	SELECT DISTINCT recommend FROM dbo.MemberInfo WITH (NOLOCK)

	CREATE TABLE #tempData
	(
		AffId		INT,
		IBCCustId	INT,
		Currency	INT,
		Turnover	MONEY,
		Winloss		MONEY,
		AWinloss	MONEY,
		AComm		MONEY
	)

	-- AG Casino
	IF @ProductId = 9
	BEGIN
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
	END
	-- Gold Deluxe
	ELSE IF @ProductId = 17
	BEGIN
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
				SUM(ISNULL(b.winlost, 0) - ISNULL(b.stake, 0)) AS Winloss
			FROM bodb_PlaytechCS.dbo.bettrans_GoldDeluxe b WITH (NOLOCK)
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
	END
	-- Exchange
	ELSE IF @ProductId = 19
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss,
			AWinloss,
			AComm
		)
		SELECT
			a.AffId,
			a.IBCCustId,
			a.currency,
			a.Turnover,
			a.Winloss,
			-a.Winloss * (1 - ISNULL(r.Rate, 0)) AS AWinloss,
			a.AComm
		FROM
		(
			SELECT
				mi.AffId,
				mi.IBCCustId,
				mi.currency,
				SUM(ISNULL(b.stakeTotal / b.ExVirtualRate, 0))		AS Turnover,
				SUM(ISNULL(b.profitLoss / b.ExVirtualRate, 0))		AS Winloss,
				SUM(ISNULL(b.agentCommission / b.ExVirtualRate, 0)) AS AComm
			FROM bodb_3rdProduct.dbo.Sum_winloss_Exchange b WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = b.custid
			WHERE b.settledDate >= @WinlostDate AND b.settledDate < DATEADD(DAY, 1, @WinlostDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
						AND mi.IBCCustId = mr.IBCCustId
				)
			GROUP BY
				mi.AffId,
				mi.IBCCustId,
				mi.currency
		) AS a
			OUTER APPLY (
				SELECT DI_Rate AS Rate FROM bodb_licensee.dbo.LA_f_ChargeInfo('14', @WinlostDate, @WinlostDate, 'BX', 'OA', 1)
				WHERE DI_Rate > 0 AND ChargeType = 1
			) AS r
	END

	IF EXISTS (
		SELECT 1
		FROM #tempData d
			FULL OUTER JOIN dbo.rptMemberDaily md WITH (NOLOCK)
				ON		d.AffId			= md.AffId
					AND d.IBCCustId		= md.IBCCustId
					AND md.WinlostDate	= @WinlostDate
					AND md.ProductId	= @ProductId
		WHERE (ISNULL(md.WinlostDate, @WinlostDate) = @WinlostDate AND ISNULL(md.ProductId, @ProductId) = @ProductId)
			AND (
				d.AffId IS NULL
				OR md.AffId IS NULL
				OR d.Turnover <> md.Turnover
				OR d.Winloss <> md.Winloss
				OR ISNULL(d.AWinloss, 0) <> ISNULL(md.AWinloss, 0)
				OR ISNULL(d.AComm, 0) <> ISNULL(md.AComm, 0)
			)
	)
		SELECT @IsMismatch = 1
	ELSE
		SELECT @IsMismatch = 0

	IF @IsMismatch = 1
	BEGIN
		IF @IsCheckDataOnly = 0
		BEGIN
			MERGE dbo.rptMemberDaily AS TARGET
			USING
				(
					SELECT AffId,IBCCustId,Turnover,Winloss,AWinloss,AComm,Currency,e.ActualRate AS ExRate,e.ActualRate2 AS AffExRate
					FROM #tempData d
						CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(d.Currency, @WinlostDate) e
				) AS SOURCE
				ON		TARGET.WinlostDate	= @WinlostDate
					AND TARGET.ProductId	= @ProductId
					AND TARGET.AffId		= SOURCE.AffId
					AND TARGET.IBCCustId	= SOURCE.IBCCustId
			WHEN MATCHED THEN UPDATE
				SET TARGET.Deposit			= 0,
					TARGET.Withdrawal		= 0,
					TARGET.Bonus			= 0,
					TARGET.Adjustment		= 0,
					TARGET.Turnover			= SOURCE.Turnover,
					TARGET.Winloss			= SOURCE.Winloss,
					TARGET.AWinloss			= SOURCE.AWinloss,
					TARGET.AComm			= SOURCE.AComm
			WHEN NOT MATCHED BY TARGET THEN
				INSERT
				(
					WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,AWinloss,AComm,Currency,ExRate,AffExRate
				)
				VALUES
				(
					@WinlostDate,AffId,IBCCustId,@ProductId,0,0,0,0,Turnover,Winloss,AWinloss,AComm,Currency,ExRate,AffExRate
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @WinlostDate AND TARGET.ProductId = @ProductId THEN DELETE;
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
				ISNULL(md.Winloss, 0)	AS Winloss_Target,
				ISNULL(d.AWinloss, 0)	AS AWinloss_Source,
				ISNULL(md.AWinloss, 0)	AS AWinloss_Target,
				ISNULL(d.AComm, 0)		AS AComm_Source,
				ISNULL(md.AComm, 0)		AS AComm_Target
			FROM #tempData d
				FULL OUTER JOIN dbo.rptMemberDaily md WITH (NOLOCK)
					ON		d.AffId			= md.AffId
						AND d.IBCCustId		= md.IBCCustId
						AND md.WinlostDate	= @WinlostDate
						AND md.ProductId	= @ProductId
			WHERE d.AffId IS NULL
				OR md.AffId IS NULL
				OR d.Turnover <> md.Turnover
				OR d.Winloss <> md.Winloss
				OR ISNULL(d.AWinloss, 0) <> ISNULL(md.AWinloss, 0)
				OR ISNULL(d.AComm, 0) <> ISNULL(md.AComm, 0)
		END
	END

	DROP TABLE #tempData
END
