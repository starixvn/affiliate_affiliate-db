ALTER PROCEDURE [dbo].[Aff_BannerSelByParentCate] 
	@Category VARCHAR(50) = NULL
	,@Language VARCHAR(50) = NULL
	,@ImageType VARCHAR(50) = NULL
	,@Size VARCHAR(50) = NULL
	,@Currency VARCHAR(50) = NULL
	,@Type VARCHAR(50) = 0
	,@AffType TINYINT
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*Created: 2012-02-09 - Frank
Task : IRP-671-Banner Media
DB:  DB052.Affiliate_12BET

Revisions:    
	- 20140226@Bobby: Apply AffType	
			  
Param's Explanation:
• @Category : Search by all sub category which belong to Category
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows
• @AffType: Affiliate Type
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MediaType VARCHAR(50)

	SET @MediaType = 'CategoryMedia' + @Category

	--count nrows
	SELECT @NRows = count(1)
	FROM Banners_1 WITH (NOLOCK)
	WHERE Category IN (
			SELECT b.Value
			FROM BannerTypes_1 b
			WHERE b.Type LIKE @MediaType
			)
		AND LANGUAGE = coalesce(@Language, LANGUAGE)
		AND ImageType = coalesce(@ImageType, ImageType)
		AND Size = coalesce(@Size, Size)
		AND isnull(Currency, '') = coalesce(@Currency, Currency, '')
		AND ISNULL([Type], 0) = @Type
		AND ISNULL([AffType], 0) = @AffType

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT BannerID
		,FileName
		,Category
		,[Language]
		,ImageType
		,[Size]
		,Lastupdate
		,Currency
	FROM (
		SELECT TOP (@RowEnd) ROW_NUMBER() OVER (
				ORDER BY bannerid DESC
				) AS TheCount
			,BannerID
			,FileName
			,Category
			,[Language]
			,ImageType
			,[Size]
			,Lastupdate
			,Currency
		FROM Banners_1 WITH (NOLOCK)
		WHERE Category IN (
				SELECT b.Value
				FROM BannerTypes_1 b
				WHERE b.Type LIKE @MediaType
				)
			AND LANGUAGE = coalesce(@Language, LANGUAGE)
			AND ImageType = coalesce(@ImageType, ImageType)
			AND Size = coalesce(@Size, Size)
			AND isnull(Currency, '') = coalesce(@Currency, Currency, '')
			AND ISNULL([Type], 0) = @Type
			AND ISNULL([AffType], 0) = @AffType
		) x
	WHERE x.TheCount BETWEEN @RowStart AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSelByParentCate] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSelByParentCate] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSelByParentCate] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelByParentCate] TO [VNTeam]
