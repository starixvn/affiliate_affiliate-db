/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_MonthlyEarning]
	@AffId		INT
	,@FromDate	SMALLDATETIME
	,@ToDate	SMALLDATETIME
AS

/*
	Created: 20211222@Percy
	DB: DBAFF-Affiliate_Athena000
	Task: Monthy Earning

	Revisions:
		- 20211222@Percy: Initialize SP [RedmineID: #165777]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromMonthDate SMALLDATETIME, @ToMonthDate SMALLDATETIME
	SELECT  @FromMonthDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0)
	SELECT  @ToMonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0))

	DECLARE @CurrentMonth SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	-- Group Setting
	DECLARE @GroupSetting TABLE (MonthDate SMALLDATETIME, GroupId INT, QMTurnover MONEY)
	INSERT INTO @GroupSetting (MonthDate, GroupId, QMTurnover)
	SELECT @CurrentMonth AS MonthDate, cg.GroupId, cg.QualifiedAmount
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
	WHERE ai.AffId = @AffId AND @CurrentMonth BETWEEN @FromMonthDate AND @ToMonthDate

	UNION ALL
	SELECT cgh.MonthDate, cgh.GroupId, cgh.QualifiedAmount
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) ON agh.GroupId = cgh.GroupId AND agh.MonthDate = cgh.MonthDate
	WHERE agh.AffId = @AffId AND agh.MonthDate BETWEEN @FromMonthDate AND @ToMonthDate


	-- Deduction Setting
	DECLARE @DeductionSetting TABLE (MonthDate SMALLDATETIME, GroupId INT, ProductId TINYINT, Bonus DECIMAL(9,8), Marketing DECIMAL(9,8), PSP DECIMAL(9,8), OddsFee DECIMAL(9,8), PlayerComm DECIMAL(9,8))
	INSERT INTO @DeductionSetting (MonthDate, GroupId, ProductId, Bonus, Marketing, PSP, OddsFee, PlayerComm)
	SELECT t.MonthDate, t.GroupId, dt.ProductId
		,SUM(CASE WHEN dt.DTypeName = 'Bonus'		THEN t.DeductedPercentage ELSE 0 END) AS Bonus
		,SUM(CASE WHEN dt.DTypeName = 'Marketing'	THEN t.DeductedPercentage ELSE 0 END) AS Marketing
		,SUM(CASE WHEN dt.DTypeName = 'PSP'			THEN t.DeductedPercentage ELSE 0 END) AS PSP
		,SUM(CASE WHEN dt.DTypeName = 'Odds Fee'	THEN t.DeductedPercentage ELSE 0 END) AS OddsFee
		,SUM(CASE WHEN dt.DTypeName = 'PlayerComm'	THEN t.DeductedPercentage ELSE 0 END) AS PlayerComm
	FROM (
		SELECT @CurrentMonth AS MonthDate, ds.GroupId, ds.DeductionId, ds.DeductedPercentage
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.DeductionSetting ds WITH (NOLOCK) ON ai.GroupId = ds.GroupId
			INNER JOIN dbo.DeductionType dt WITH(NOLOCK) ON dt.DTypeID = ds.DeductionID
			INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = dt.ProductID
		WHERE ai.AffId = @AffId AND @CurrentMonth BETWEEN @FromMonthDate AND @ToMonthDate AND p.IsEnabled = 1

		UNION ALL
		SELECT dsh.MonthDate, dsh.GroupId, dsh.DeductionId, dsh.DeductedPercentage
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
			INNER JOIN dbo.DeductionType dt WITH(NOLOCK) ON dt.DTypeID = dsh.DeductionID
			INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = dt.ProductID
		WHERE agh.AffId = @AffId AND agh.MonthDate BETWEEN @FromMonthDate AND @ToMonthDate AND p.IsEnabled = 1
	) t
		INNER JOIN dbo.DeductionType dt WITH (NOLOCK) ON t.DeductionId = dt.DTypeId
	GROUP BY t.MonthDate, t.GroupId, dt.ProductId

	CREATE TABLE #tmpData
	(
		MonthDate		SMALLDATETIME
		,ProductId		INT
		,GroupId		INT
		,TotalQM		MONEY
		,Winlost		MONEY
		,Bonus			MONEY
		,PSP			MONEY
		,Marketing		MONEY
		,TurnOver		MONEY
		,PlayerComm		MONEY
		,TotalFee		MONEY
		,BonusFee		MONEY
		,NetWinlost		MONEY
		,Commission		DECIMAL(9, 8)
	)

	;WITH CTE_Data AS (
		SELECT t.MonthDate, ISNULL(g.GroupProductId, t.ProductId) AS ProductId, ISNULL(gs.GroupId, 0) AS GroupId
			,SUM(CASE WHEN t.TurnOver >= ISNULL(gs.QMTurnover, 0) THEN 1 ELSE 0 END) AS TotalQM
			,SUM(t.Winlost)		AS Winlost
			,SUM(t.Bonus)		AS Bonus
			,SUM(t.PSP)			AS PSP
			,SUM(t.Marketing)	AS Marketing
			,SUM(t.TurnOver)	AS TurnOver
			,SUM(t.PlayerComm)	AS PlayerComm
		FROM (
			SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, m.WinlostDate) + 1, 0)) AS MonthDate
				,m.UserName, m.ProductId
				,SUM(ISNULL(m.Winlost, 0)		* ISNULL(m.AffExRate, 1)) AS Winlost
				,SUM(ISNULL(m.Bonus, 0)		* ISNULL(m.AffExRate, 1)) AS Bonus
				,SUM(ISNULL(m.PSP, 0)			* ISNULL(m.AffExRate, 1)) AS PSP
				,SUM(ISNULL(m.Marketing, 0)	* ISNULL(m.AffExRate, 1)) AS Marketing
				,SUM(ISNULL(m.TurnOver, 0)	* ISNULL(m.AffExRate, 1)) AS TurnOver
				,SUM(ISNULL(m.PlayerComm, 0)	* ISNULL(m.AffExRate, 1)) AS PlayerComm
			FROM dbo.MemberDaily m WITH (NOLOCK)
				INNER JOIN dbo.Product p WITH(NOLOCK) ON p.ProductID = m.ProductID
			WHERE m.AffId = @AffId AND p.IsEnabled = 1
				AND m.WinlostDate BETWEEN @FromMonthDate AND @ToMonthDate
			GROUP BY DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, m.WinlostDate) + 1, 0))
				,m.UserName, m.ProductId
		) t
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON t.ProductId = g.ProductId
			LEFT JOIN @GroupSetting gs ON t.MonthDate = gs.MonthDate
		GROUP BY t.MonthDate, ISNULL(g.GroupProductId, t.ProductId), ISNULL(gs.GroupId, 0)
	)
	INSERT INTO #tmpData (MonthDate, ProductId, GroupId, TotalQM, Winlost, Bonus, PSP, Marketing, TurnOver, PlayerComm, TotalFee, BonusFee)
	SELECT c.MonthDate, c.ProductId, c.GroupId, SUM(c.TotalQM), SUM(c.Winlost), SUM(c.Bonus), SUM(c.PSP), SUM(c.Marketing), SUM(c.TurnOver), SUM(c.PlayerComm)
		,SUM(ABS(c.PSP) * ISNULL(ds.PSP, 0) + ABS(c.Winlost) * ISNULL(ds.OddsFee, 0) + ABS(c.Winlost) * ISNULL(ds.Marketing, 0) + ABS(c.PlayerComm) * ISNULL(ds.PlayerComm, 0))
		,SUM(ABS(c.Bonus) * ISNULL(ds.Bonus, 0))
	FROM CTE_Data c
		LEFT JOIN @DeductionSetting ds ON c.MonthDate = ds.MonthDate AND c.ProductId = ds.ProductId AND c.GroupId = ds.GroupId
	GROUP BY c.MonthDate, c.ProductId, c.GroupId

	UPDATE t
	SET t.NetWinlost = -t.Winlost - t.TotalFee
		,t.Commission = ISNULL(b.Commission, 0)
	FROM #tmpData t
		OUTER APPLY (
			SELECT TOP 1 a.Commission
			FROM (
				SELECT gs.Commission
				FROM dbo.GroupSetting gs WITH (NOLOCK)
				WHERE t.GroupId = gs.GroupId
					AND t.ProductId = gs.ProductId
					AND t.MonthDate = @CurrentMonth
					AND (
						FLOOR(ABS(-t.Winlost - t.TotalFee)) BETWEEN gs.MinAmount AND gs.MaxAmount
						OR t.TotalQM BETWEEN gs.MinQM AND gs.MaxQM
					)

				UNION ALL
				SELECT gsh.Commission
				FROM dbo.GroupSettingHistory gsh WITH (NOLOCK)
				WHERE t.GroupId = gsh.GroupId
					AND t.ProductId = gsh.ProductId
					AND t.MonthDate = gsh.MonthDate
					AND (
						FLOOR(ABS(-t.Winlost - t.TotalFee)) BETWEEN gsh.MinAmount AND gsh.MaxAmount
						OR t.TotalQM BETWEEN gsh.MinQM AND gsh.MaxQM
					)
			) a
			ORDER BY a.Commission
		) b

	-- Default Setting
	DECLARE @NoCommissionGroupId INT = 0
	SELECT  @NoCommissionGroupId = ISNULL(GroupId, 0) FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = 'NoCommission'

	DECLARE @IsForceMinNegativeCommission BIT = 0, @MinimumNegativeCommission FLOAT = 0.1
	SELECT  @MinimumNegativeCommission 	= CASE WHEN SName = 'AFF_MinNegativeCommission'			THEN ISNULL(SValue, @MinimumNegativeCommission)		ELSE @MinimumNegativeCommission END
		,@IsForceMinNegativeCommission 	= CASE WHEN SName = 'AFF_ForceMinNegativeCommission'	THEN ISNULL(SValue, @IsForceMinNegativeCommission)	ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')

	IF @IsForceMinNegativeCommission = 1
	BEGIN
		UPDATE t
		SET t.Commission = @MinimumNegativeCommission
		FROM #tmpData t
			CROSS APPLY (
				SELECT gs.ProductId
				FROM dbo.GroupSetting gs WITH (NOLOCK)
				WHERE t.GroupId = gs.GroupId AND t.ProductId = gs.ProductId AND t.MonthDate = @CurrentMonth

				UNION ALL
				SELECT gsh.ProductId
				FROM dbo.GroupSettingHistory gsh WITH (NOLOCK)
				WHERE t.GroupId = gsh.GroupId AND t.ProductId = gsh.ProductId AND t.MonthDate = gsh.MonthDate
			) g
		WHERE t.GroupId IN (0, @NoCommissionGroupId)
			AND t.NetWinlost < 0 AND t.Commission = 0 AND g.ProductId IS NOT NULL
	END

	-- Deducted Amount
	DECLARE @DeductionAmount TABLE (MonthDate SMALLDATETIME, GroupId INT, Amount MONEY)
	INSERT INTO @DeductionAmount (MonthDate, GroupId, Amount)
	SELECT @CurrentMonth, ds.GroupId, SUM(ISNULL(t.Amount * ds.DeductedPercentage, 0))
    FROM dbo.AffDeductionTransaction t WITH (NOLOCK)
		INNER JOIN dbo.DeductionSetting ds WITH (NOLOCK) ON t.DTypeId = ds.DeductionId
	WHERE t.AffId = @AffId AND t.ProductId = 0
		AND t.MonthDate = @CurrentMonth
		AND @CurrentMonth BETWEEN @FromMonthDate AND @ToMonthDate
	GROUP BY ds.GroupId

	UNION ALL
	SELECT t.MonthDate, dsh.GroupId, SUM(ISNULL(t.Amount * dsh.DeductedPercentage, 0))
    FROM dbo.AffDeductionTransaction t WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON t.DTypeId = dsh.DeductionId AND t.MonthDate = dsh.MonthDate
	WHERE t.AffId = @AffId AND t.ProductId = 0
		AND t.MonthDate BETWEEN @FromMonthDate AND @ToMonthDate
	GROUP BY t.MonthDate, dsh.GroupId

	-- Return data
	SELECT t.MonthDate, SUM((NetWinlost - BonusFee) * ISNULL(Commission, 0) - ISNULL(d.Amount, 0)) AS Amount
	FROM #tmpData t
		LEFT JOIN @DeductionAmount d ON t.MonthDate = d.MonthDate AND t.GroupId = d.GroupId AND t.GroupId NOT IN (0, @NoCommissionGroupId)
	GROUP BY t.MonthDate
END
GO