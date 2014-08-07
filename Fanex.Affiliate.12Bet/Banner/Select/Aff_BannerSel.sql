ALTER PROC [dbo].[Aff_BannerSel] 
	@Category VARCHAR(50) = NULL
	,@Language VARCHAR(50) = NULL
	,@ImageType VARCHAR(50) = NULL
	,@Size VARCHAR(50) = NULL
	,@Currency VARCHAR(50) = NULL
	,@Type VARCHAR(50) = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@DeviceType TINYINT = 0
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*Created: 20090328@DungTong
Task : Search all Aff Banner Paging
DB:  DB052.Affiliate_12BET

Revisions:    
	- 20120110@Johnny: Filter by Type(0: normal banner; 1: media banners)
	- 20140707@Bobby: Include DeviceType info
			  
Param's Explanation:
• @Category : Search by Category value=null :search all
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/
BEGIN
	SET NOCOUNT ON

	--count nrows
	SELECT @NRows = count(1)
	FROM Banners WITH (NOLOCK)
	WHERE Category = coalesce(@Category, Category)
		AND LANGUAGE = coalesce(@Language, LANGUAGE)
		AND ImageType = coalesce(@ImageType, ImageType)
		AND Size = coalesce(@Size, Size)
		AND isnull(Currency, '') = coalesce(@Currency, Currency, '')
		AND ISNULL([Type], 0) = @Type
		AND DeviceType = @DeviceType

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
		,DeviceType
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
			,[dbo].[Aff_GetDeviceType](DeviceType) DeviceType
		FROM Banners WITH (NOLOCK)
		WHERE Category = coalesce(@Category, Category)
			AND LANGUAGE = coalesce(@Language, LANGUAGE)
			AND ImageType = coalesce(@ImageType, ImageType)
			AND Size = coalesce(@Size, Size)
			AND isnull(Currency, '') = coalesce(@Currency, Currency, '')
			AND ISNULL([Type], 0) = @Type
			AND DeviceType = @DeviceType
		) x
	WHERE x.TheCount BETWEEN @RowStart
			AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSel] TO [VNTeam]
