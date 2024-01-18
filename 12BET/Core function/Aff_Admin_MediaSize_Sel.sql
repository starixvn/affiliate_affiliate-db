/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaSize_Sel]
	@Languages			VARCHAR(MAX)
	,@TargetProductId	INT = 0
	,@AffType			TINYINT = NULL
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Get Size

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20191210@Percy: Add filters [RedmineID: #121973]
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
		- 20200731@Percy: Check permission market (language) by user login [RedmineID: #121975]
		- 20231117@Eddie: Use TargetProduct for MediaSize [RedmineID: #181590]

	Param's Explanation:
		- @Languages:  get from table TargetCountry, ex: 'Korean' or 'Vietnamese', not use 'English (Europe)' and 'Spanish'
		- @TargetProductId:  get from table TargetProduct, ex: 1 (Sports) or 2 (Exchange)
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Languages = ISNULL(@Languages, '')

	SELECT @TargetProductId = ISNULL(@TargetProductId, 0)

	;WITH CTE_Size AS (
		SELECT Size
		FROM dbo.Banners b WITH (NOLOCK)
		WHERE ImageType <> 'Text'
		  AND (',' + @Languages + ',' LIKE '%,' + b.Language + ',%')
		  AND ((@TargetProductId = 0) OR ',' + b.TargetProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(5), @TargetProductId) + ',%')
		  AND (@AffType IS NULL OR ',' + b.AffTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @AffType) + ',%')
		GROUP BY Size
	)
	SELECT
		ROW_NUMBER() OVER(ORDER BY CONVERT(INT, h.val), CONVERT(INT, w.val)) AS SizeId
		,s.Size
	FROM CTE_Size s
		CROSS APPLY (SELECT val FROM dbo.strSplit(s.Size, 'x') WHERE [rank] = 1) h -- height
		CROSS APPLY (SELECT val FROM dbo.strSplit(s.Size, 'x') WHERE [rank] = 2) w -- weight
	ORDER BY SizeId
END
GO