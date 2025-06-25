/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroup_Sel]
	@GroupId INT = 0,
	@GroupName NVARCHAR(100) = NULL,
	@GroupTypeId INT = NULL,
	@PageIndex	INT = 1,
	@PageSize	INT = 20,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Affiliate - Commission Group

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
        - 20250320@Sally: Exclude StraightSetting [RedmineID: #219936]
		- 20250526@Lewis: Exclude grouptypeid = 3 4 [RedmineID: #228530]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsTest BIT
	SELECT  @IsTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	DECLARE @RowStart INT, @RowEnd INT

	IF @GroupId <> 0
	BEGIN
		SELECT  @RowStart = 1, @RowEnd = 1
	END
	ELSE
	BEGIN
		SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1,
				@RowEnd = @RowStart + @PageSize - 1
	END

	DECLARE @Group TABLE (RowIDX INT, GroupId INT NOT NULL PRIMARY KEY, NRows INT)
	
	INSERT INTO @Group (RowIDX, GroupId, NRows)
	SELECT RowIDX, GroupId, NRows
	FROM
	(
		SELECT ROW_NUMBER() OVER(ORDER BY cg.GroupId ASC) AS RowIDX, cg.GroupId, COUNT(1) OVER() AS NRows
		FROM dbo.CommGroup cg WITH (NOLOCK)
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON cg.Creator = au.custid
		WHERE (@GroupId = 0 OR cg.GroupId = @GroupId)
			AND cg.IsDeleted = 0
			AND cg.GroupName LIKE '%' + ISNULL(@GroupName, '') + '%'
			AND (cg.GroupTypeId = @GroupTypeId OR @GroupTypeId IS NULL)
			AND cg.GroupTypeId = 1 --revenue only
			AND EXISTS (SELECT 1 FROM dbo.TierSetting t WITH (NOLOCK) WHERE cg.GroupId = t.GroupId)
			AND EXISTS (
				SELECT 1 FROM dbo.Deductions d WITH (NOLOCK)
					INNER JOIN dbo.DeductionSetting ds WITH (NOLOCK) ON d.DeductionId = ds.DeductionID
				WHERE cg.GroupId = ds.GroupId
			)
	) AS g
	WHERE RowIDX BETWEEN @RowStart AND @RowEnd

	SELECT TOP 1 @NRows = NRows FROM @Group

	-- General information
	SELECT
		g.RowIDX,
		g.GroupId,
		cg.GroupName,
		cg.GroupTypeId,
		gt.GroupTypeName,
		gt.GroupTypeBy,
		cg.CreatedDate,
		au.Username AS Creator,
		cg.Description,
		cg.SubCommRate,
		cg.QMTurnover,
		ISNULL(s.IsActivePlayerSum, 1) AS IsActivePlayerSum,
		ISNULL(n.NoAffs, 0) AS NoAffs
	FROM dbo.CommGroup cg WITH (NOLOCK)
		INNER JOIN @Group g ON cg.GroupId = g.GroupId
		INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON gt.GroupTypeId = cg.GroupTypeId
		LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON cg.Creator = au.custid
		OUTER APPLY (
			SELECT COUNT(1) AS NoAffs FROM dbo.AffInfo ai WITH (NOLOCK) WHERE ai.GroupId = g.GroupId
		) AS n
		OUTER APPLY (
			SELECT TOP(1) IsActivePlayerSum FROM dbo.TierSetting ts WITH(NOLOCK) WHERE ts.GroupId = cg.GroupId
		) AS s

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
		INNER JOIN @Group g ON gs.GroupId = g.GroupId
	ORDER BY
		gs.GroupId,
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
		INNER JOIN @Group g ON ds.GroupId = g.GroupId
	WHERE dt.IsTest <= @IsTest AND dt.IsDeleted = 0
	GROUP BY
		ds.GroupId,
		ds.DeductionId,
		dt.DeductionName,
		ds.GroupProductId,
		ds.DeductedPercentage,
		ds.DeductedAmount,
		ds.IsDeductedPercent
END
GO