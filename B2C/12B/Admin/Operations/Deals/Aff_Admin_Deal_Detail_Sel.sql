/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_Deal_Detail_Sel
    @GroupId INT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Deal Detail

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]
*/

BEGIN
    SET NOCOUNT ON;

    SELECT 
		cg.GroupId,
        cg.GroupName AS DealName,
        cg.GroupTypeId AS DealType,
        cg.Description,
		cg.SubCommRate,
		--Revenue
		cg.QMTurnover,
		--CPA
		cg.CountryCodes,
		cg.ActiveDays,
		cg.HoldingTickets,
		cg.HoldingDays,
		cg.Quota,
		cg.IsInstant,
		a.IsActivePlayerSum
    FROM CommGroup cg WITH (NOLOCK)
	OUTER APPLY (SELECT TOP 1 IsActivePlayerSum FROM TierSetting gs WITH (NOLOCK) WHERE cg.GroupId = gs.GroupId) a
    WHERE cg.GroupId = @GroupId
	  AND cg.IsDeleted = 0
	
	--Revenue

		-- Tier List
		SELECT
			gs.GroupId,
			gs.TierId,
			gs.MinAmount,
			gs.MaxAmount,
			gs.MinQM,
			gs.MaxQM,
			gs.Commission,
			gs.GroupProductId
		FROM dbo.TierSetting gs WITH (NOLOCK)
		WHERE gs.GroupId = @GroupId
		ORDER BY
			gs.GroupProductId,
			gs.TierId

		-- Deduction List
		SELECT
			ds.GroupId,
			ds.DeductionId,
			dt.DeductionName,
			STUFF(
				(SELECT	',' + CONVERT(VARCHAR(10), d.ProductId)
					FROM dbo.DeductionSetting d WITH (NOLOCK)
						LEFT JOIN dbo.Aff_f_GroupProduct() gp ON d.ProductID = gp.ProductId 
															AND gp.ProductId <> gp.GroupProductId 										
					WHERE gp.ProductId IS NULL
						AND ds.GroupId			= d.GroupId
						AND ds.DeductionId		= d.DeductionId
						AND ds.GroupProductId	= d.GroupProductId
						AND d.ProductId			<> 0
					FOR XML PATH (''))
					, 1, 1, '') AS ProductIds,
			ds.DeductedPercentage,
			ds.DeductedAmount,
			ds.IsDeductedPercent,
			ds.GroupProductId
		FROM dbo.DeductionSetting ds WITH (NOLOCK)
			INNER JOIN dbo.Deductions dt WITH (NOLOCK) ON ds.DeductionId = dt.DeductionId
		WHERE ds.GroupId = @GroupId AND dt.IsDeleted = 0
		GROUP BY
			ds.GroupId,
			ds.DeductionId,
			dt.DeductionName,
			ds.GroupProductId,
			ds.DeductedPercentage,
			ds.DeductedAmount,
			ds.IsDeductedPercent
	
	--CPA
		--TierSetting
		SELECT
			GroupId,
			GroupProductId,
			TierId,
			MinFDM,
			MaxFDM,
			MinTotalDeposit,
			MaxTotalDeposit,
			MinTO,
			MaxTO,
			CPAAmount
		FROM CPATierSetting WITH (NOLOCK)
		WHERE GroupId = @GroupId
			AND ToDate = '9999-12-31'
		ORDER BY
			GroupProductId,
			TierId

		--Products
		SELECT
			d.GroupId,
			d.GroupProductId,
			STRING_AGG(CAST(d.ProductId AS VARCHAR(MAX)),',') AS ProductIds
		FROM CPAProductSetting d WITH (NOLOCK)
		LEFT JOIN dbo.Aff_f_GroupProduct() gp ON d.ProductID = gp.ProductId AND gp.ProductId <> gp.GroupProductId
		WHERE GroupId = @GroupId
			AND ToDate = '9999-12-31'
			AND gp.ProductId IS NULL
		GROUP BY
			d.GroupId,
			d.GroupProductId
		ORDER BY
			GroupProductId



END
GO
