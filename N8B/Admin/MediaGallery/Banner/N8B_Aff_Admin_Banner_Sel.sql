/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Sel]
	@BannerId		INT = 0
	,@TargetId		TINYINT = 0
	,@Language		VARCHAR(100) = NULL
	,@Category		VARCHAR(50) = NULL
	,@SubCategory	VARCHAR(50) = NULL
	,@Currency		VARCHAR(10) = NULL
	,@AffType		VARCHAR(10) = NULL
	,@DeviceType	VARCHAR(10) = NULL
	,@Size			VARCHAR(20) = NULL
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Media Gallery - Banner - Select

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

	Param's Explanation:
		- @TargetId:
			0: All banners
			1: Member banner
			2: Affiliate banner
*/

BEGIN
	SET NOCOUNT ON

	IF @BannerId <> 0
	BEGIN
		SELECT MediaId AS BannerId,TargetId,FileName,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,UpdatedDate
		FROM dbo.MediaGallery WITH (NOLOCK)
		WHERE MediaId = @BannerId
			AND (@TargetId = 0 OR TargetId = @TargetId)
			AND ImageType = 'Image'
	END
	ELSE
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.MediaGallery WITH (NOLOCK)
		WHERE (@TargetId = 0 OR TargetId = @TargetId)
			AND ImageType = 'Image'
			AND (@Language IS NULL OR Language = @Language)
			AND (@Size IS NULL OR Size = @Size)
			AND (@Category IS NULL OR ',' + Categories + ',' LIKE '%,' + @Category + ',%')
			AND (@SubCategory IS NULL OR ',' + SubCategories + ',' LIKE '%,' + @SubCategory + ',%')
			AND (@Currency IS NULL OR ',' + Currencies + ',' LIKE '%,' + @Currency + ',%')
			AND (@AffType IS NULL OR ',' + AffTypes + ',' LIKE '%,' + @AffType + ',%')
			AND (@DeviceType IS NULL OR ',' + DeviceTypes + ',' LIKE '%,' + @DeviceType + ',%')

		IF @NRows = 0
			RETURN

		SELECT MediaId AS BannerId,TargetId,FileName,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,UpdatedDate
		FROM (
			SELECT MediaId,TargetId,FileName,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,UpdatedDate
				,ROW_NUMBER() OVER(ORDER BY MediaId DESC) AS RowNum
			FROM dbo.MediaGallery WITH (NOLOCK)
			WHERE (@TargetId = 0 OR TargetId = @TargetId)
				AND ImageType = 'Image'
				AND (@Language IS NULL OR Language = @Language)
				AND (@Size IS NULL OR Size = @Size)
				AND (@Category IS NULL OR ',' + Categories + ',' LIKE '%,' + @Category + ',%')
				AND (@SubCategory IS NULL OR ',' + SubCategories + ',' LIKE '%,' + @SubCategory + ',%')
				AND (@Currency IS NULL OR ',' + Currencies + ',' LIKE '%,' + @Currency + ',%')
				AND (@AffType IS NULL OR ',' + AffTypes + ',' LIKE '%,' + @AffType + ',%')
				AND (@DeviceType IS NULL OR ',' + DeviceTypes + ',' LIKE '%,' + @DeviceType + ',%')
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO