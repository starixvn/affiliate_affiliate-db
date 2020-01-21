/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Sel]
	@BannerId		INT = 0
	,@Category		VARCHAR(50) = NULL
	,@Language		VARCHAR(50) = NULL
	,@Currency		VARCHAR(50) = NULL
	,@ImageType		VARCHAR(50) = NULL
	,@Size			VARCHAR(50) = NULL
	,@AffType		TINYINT = 0
	,@DeviceType	TINYINT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Banner - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200120@Percy: Return more field: LastUpdate [RedmineID: #127345]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblCategory TABLE (Category VARCHAR(50))
	INSERT INTO @tblCategory (Category)
	SELECT @Category
	UNION
	SELECT Category FROM dbo.Aff_f_MediaCategory_Sel() WHERE ParentCategory = @Category
	
	IF @BannerId <> 0
	BEGIN
		SELECT BannerId, FileName, Category, Language, Currency, DeviceType, ImageType, Size, AffType, LastUpdate
		FROM dbo.Banners_1 WITH (NOLOCK)
		WHERE BannerId = @BannerId
	END
	ELSE
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.Banners_1 b WITH (NOLOCK)
		WHERE ImageType <> 'Text'
			AND (@Category IS NULL OR EXISTS (SELECT 1 FROM @tblCategory t WHERE t.Category = b.Category))
			AND (@Language IS NULL OR Language = @Language)
			AND (@ImageType IS NULL OR ImageType = @ImageType)
			AND (@Size IS NULL OR Size = @Size)
			AND (@Currency IS NULL OR Currency = @Currency)
			AND (@AffType IS NULL OR ISNULL(AffType, 0) = @AffType)
			AND (@DeviceType IS NULL OR ISNULL(DeviceType, 0) = @DeviceType)

		IF @NRows = 0
			RETURN

		SELECT BannerId, FileName, Category, Language, Currency, DeviceType, ImageType, Size, AffType, LastUpdate
		FROM (
			SELECT BannerId, FileName, Category, Language, Currency, DeviceType, ImageType, Size, AffType, LastUpdate
				,ROW_NUMBER() OVER(ORDER BY BannerId DESC) AS RowNum
			FROM dbo.Banners_1 b WITH (NOLOCK)
			WHERE ImageType <> 'Text'
				AND (@Category IS NULL OR EXISTS (SELECT 1 FROM @tblCategory t WHERE t.Category = b.Category))
				AND (@Language IS NULL OR Language = @Language)
				AND (@ImageType IS NULL OR ImageType = @ImageType)
				AND (@Size IS NULL OR Size = @Size)
				AND (@Currency IS NULL OR Currency = @Currency)
				AND (@AffType IS NULL OR ISNULL(AffType, 0) = @AffType)
				AND (@DeviceType IS NULL OR ISNULL(DeviceType, 0) = @DeviceType)
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO