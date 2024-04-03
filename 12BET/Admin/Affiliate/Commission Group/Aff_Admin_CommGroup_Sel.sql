/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Sel]
	@GroupId INT = 0,
	@GroupName NVARCHAR(100) = NULL,
	@PageIndex	INT = 1,
	@PageSize	INT = 20,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Affiliate - Commission Group

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
		- 20240326@Eddie: Change metadata "bodbAdminNet" [RedmineID: #201095]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsTest BIT, @MonthDate SMALLDATETIME 
	SELECT  @IsTest = dbo.f_Aff_CheckSPVersion(@@PROCID)
		, @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

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
		WHERE (@GroupId = 0 OR cg.GroupId = @GroupId) AND cg.IsDeleted = 0
			AND cg.GroupName LIKE '%' + ISNULL(@GroupName, '') + '%'
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
		cg.CreatedDate,
		u.Username AS Creator,
		cg.Description,
		cg.QMTurnover,
		cg.NextQMTurnover,
		ISNULL(his.IsApplyBonus, 0) AS IsApplyBonus,
		ISNULL(cg.IsApplyBonus, 0) AS NextIsApplyBonus,
		ISNULL(n.NoAffs, 0) AS NoAffs
	FROM dbo.CommGroup cg WITH (NOLOCK)
		INNER JOIN @Group g ON cg.GroupId = g.GroupId
		LEFT JOIN dbo.Users u WITH (NOLOCK) ON cg.Creator = u.CustId
		OUTER APPLY (
			SELECT COUNT(1) AS NoAffs FROM dbo.AffInfo ai WITH (NOLOCK) WHERE ai.GroupId = g.GroupId
		) AS n
		OUTER APPLY (
			SELECT TOP 1 his.IsApplyBonus
			FROM dbo.CommGroupHistory his WITH (NOLOCK) 
			WHERE his.GroupId = cg.GroupId AND his.MonthDate = @MonthDate
		) AS his

	-- Tier List
	SELECT
		gs.GroupId,
		gs.TierId,
		gs.MinAmount,
		gs.MaxAmount,
		gs.MinQM,
		gs.MaxQM,
		gs.Commission
	FROM dbo.TierSetting gs WITH (NOLOCK)
		INNER JOIN @Group g ON gs.GroupId = g.GroupId
	ORDER BY
		gs.GroupId,
		gs.TierId

	-- Deduction List
	SELECT
		ds.GroupId,
		ds.DeductionId,
		dt.DeductionName,
		STUFF(
			(SELECT	',' + CONVERT(VARCHAR(10), d.ProductId)
				FROM dbo.DeductionSetting d WITH (NOLOCK)
				WHERE ds.GroupId					= d.GroupId
					AND ds.DeductionId				= d.DeductionId
					AND ds.GroupProductId			= d.GroupProductId
					AND ds.NextGroupProductId		= d.NextGroupProductId
					AND ds.DeductedPercentage		= d.DeductedPercentage
					AND ds.NextDeductedPercentage	= d.NextDeductedPercentage
				FOR XML PATH (''))
				, 1, 1, '') AS ProductIds,
		ds.DeductedPercentage,
		ds.NextDeductedPercentage
	FROM dbo.DeductionSetting ds WITH (NOLOCK)
		INNER JOIN dbo.Deductions dt WITH (NOLOCK) ON ds.DeductionId = dt.DeductionId
		INNER JOIN @Group g ON ds.GroupId = g.GroupId
	WHERE dt.IsTest <= @IsTest AND dt.IsDeleted = 0
	GROUP BY
		ds.GroupId,
		ds.DeductionId,
		dt.DeductionName,
		ds.GroupProductId,
		ds.NextGroupProductId,
		ds.DeductedPercentage,
		ds.NextDeductedPercentage

	--FDM TierList
	SELECT
		fdm.GroupId,
		fdm.TierId,
		fdm.MinFDM,
		fdm.MaxFDM,
		fdm.MinAmount,
		fdm.MaxAmount,
		fdm.LimitAmount,
		fdm.Commission
	FROM dbo.FDMTierSetting fdm WITH (NOLOCK)
		INNER JOIN @Group g ON fdm.GroupId = g.GroupId
	ORDER BY
		fdm.GroupId,
		fdm.TierId
END
GO