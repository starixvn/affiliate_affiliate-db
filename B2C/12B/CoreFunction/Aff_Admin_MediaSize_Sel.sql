/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_MediaSize_Sel]
	@TargetId		TINYINT = 0
	,@Language		VARCHAR(MAX) = ''
	,@Category		VARCHAR(50) = NULL
	,@SubCategory	VARCHAR(50) = NULL
	,@Currency		VARCHAR(10) = NULL
	,@ImageType		VARCHAR(10) = NULL
	,@AffType		TINYINT = NULL
	,@DeviceType	TINYINT = NULL
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Media Gallery - Get Size

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: @language - get all [RedmineID: #223644]
*/

BEGIN
	SET NOCOUNT ON

	IF @TargetId = 0 AND ISNULL(@Language,'') = '' AND @Category IS NULL AND @Currency IS NULL AND @ImageType IS NULL AND @AffType IS NULL AND @DeviceType IS NULL
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
				AND ',' + @Language + ',' LIKE '%,' + Language + ',%'
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