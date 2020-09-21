/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaSize_Sel]
	@TargetId		TINYINT = 0
	,@Language		VARCHAR(100) = NULL
	,@Category		VARCHAR(50) = NULL
	,@SubCategory	VARCHAR(50) = NULL
	,@Currency		VARCHAR(10) = NULL
	,@ImageType		VARCHAR(10) = NULL
	,@AffType		TINYINT = NULL
	,@DeviceType	TINYINT = NULL
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Media Gallery - Get Size

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	IF @TargetId = 0 AND @Language IS NULL AND @Category IS NULL AND @Currency IS NULL AND @ImageType IS NULL AND @AffType IS NULL AND @DeviceType IS NULL
	BEGIN
		WITH CTE_Size AS (
			SELECT Size FROM dbo.MediaGallery WITH (NOLOCK) WHERE (@TargetId = 0 OR TargetId = @TargetId) AND ImageType = 'Image' GROUP BY Size
		)
		SELECT
			ROW_NUMBER() OVER(ORDER BY CONVERT(INT, h.val), CONVERT(INT, w.val)) AS SizeId
			,s.Size
		FROM CTE_Size s
			CROSS APPLY (SELECT val FROM dbo.Aff_f_StringSplit(s.Size, 'x') WHERE Id = 1) h -- height
			CROSS APPLY (SELECT val FROM dbo.Aff_f_StringSplit(s.Size, 'x') WHERE Id = 2) w -- weight
		ORDER BY SizeId
	END
	ELSE
	BEGIN
		WITH CTE_Size AS (
			SELECT Size
			FROM dbo.MediaGallery WITH (NOLOCK)
			WHERE (@TargetId = 0 OR TargetId = @TargetId)
				AND ImageType = 'Image'
				AND (@Language IS NULL OR Language = @Language)
				AND (@ImageType IS NULL OR ImageType = @ImageType)
				AND (@Category IS NULL OR ',' + Categories + ',' LIKE '%,' + @Category + ',%')
				AND (@SubCategory IS NULL OR ',' + SubCategories + ',' LIKE '%,' + @SubCategory + ',%')
				AND (@Currency IS NULL OR ',' + Currencies + ',' LIKE '%,' + @Currency + ',%')
				AND (@AffType IS NULL OR ',' + AffTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @AffType) + ',%')
				AND (@DeviceType IS NULL OR ',' + DeviceTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @DeviceType) + ',%')
			GROUP BY Size
		)
		SELECT
			ROW_NUMBER() OVER(ORDER BY CONVERT(INT, h.val), CONVERT(INT, w.val)) AS SizeId
			,s.Size
		FROM CTE_Size s
			CROSS APPLY (SELECT val FROM dbo.Aff_f_StringSplit(s.Size, 'x') WHERE Id = 1) h -- height
			CROSS APPLY (SELECT val FROM dbo.Aff_f_StringSplit(s.Size, 'x') WHERE Id = 2) w -- weight
		ORDER BY SizeId
	END
END
GO