/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaSize_Sel]
	@Language	VARCHAR(50) = NULL
	,@Category	VARCHAR(50) = NULL
	,@Currency	VARCHAR(50) = NULL
	,@ImageType	VARCHAR(50) = NULL
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Get Size

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20191210@Percy: Add filters [RedmineID: #121973]
*/

BEGIN
	SET NOCOUNT ON

	IF @Language IS NULL AND @Category IS NULL AND @Currency IS NULL AND @ImageType IS NULL
	BEGIN
		SELECT
			ROW_NUMBER() OVER(ORDER BY CONVERT(INT, h.val), CONVERT(INT, w.val)) AS SizeId
			,b.Value AS Size
		FROM dbo.BannerTypes_1 b WITH (NOLOCK)
			CROSS APPLY (SELECT val FROM dbo.strSplit(b.Value, 'x') WHERE [rank] = 1) h -- height
			CROSS APPLY (SELECT val FROM dbo.strSplit(b.Value, 'x') WHERE [rank] = 2) w -- weight
		WHERE Type = 'Size'
		ORDER BY SizeId
	END
	ELSE
	BEGIN
		DECLARE @tblCategory TABLE (Category VARCHAR(50))

		IF @Category IS NOT NULL
			INSERT INTO @tblCategory (Category)
			SELECT @Category
			UNION
			SELECT Category FROM dbo.Aff_f_MediaCategory_Sel() WHERE ParentCategory = @Category
		
		SELECT
			ROW_NUMBER() OVER(ORDER BY CONVERT(INT, h.val), CONVERT(INT, w.val)) AS SizeId
			,b.Value AS Size
		FROM dbo.BannerTypes_1 b WITH (NOLOCK)
			CROSS APPLY (SELECT val FROM dbo.strSplit(b.Value, 'x') WHERE [rank] = 1) h -- height
			CROSS APPLY (SELECT val FROM dbo.strSplit(b.Value, 'x') WHERE [rank] = 2) w -- weight
		WHERE b.Type = 'Size'
			AND EXISTS (
				SELECT 1
				FROM dbo.Banners_1 bn WITH (NOLOCK)
				WHERE b.Value = bn.Size
					AND bn.ImageType <> 'Text'
					AND (@Category IS NULL OR EXISTS (SELECT 1 FROM @tblCategory t WHERE t.Category = bn.Category))
					AND (@Language IS NULL OR bn.Language = @Language)
					AND (@ImageType IS NULL OR bn.ImageType = @ImageType)
					AND (@Currency IS NULL OR bn.Currency = @Currency)
			)
		ORDER BY SizeId
	END
END
GO