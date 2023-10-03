ALTER PROCEDURE [dbo].[Aff_TextSel_1] 
	@Category VARCHAR(50) = NULL
	,@Language VARCHAR(50) = NULL
	,@Currency VARCHAR(50) = NULL
	,@DeviceType TINYINT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Select a text Banner
DB: DB052.Affiliate_12BET
Original:

Revisions:
	- 20140708@Bobby: Apply DeviceType info

Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	--count nrows
	SELECT @NRows = count(1)
	FROM Banners_1 WITH (NOLOCK)
	WHERE Category = coalesce(@Category, Category)
		AND [Language] = coalesce(@Language, [Language])
		AND [ImageType] = 'Text'
		AND isnull(Currency, '') = coalesce(@Currency, Currency, '')
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
		,Category
		,[Language]
		,Lastupdate
		,Currency
		,[Message]
		,DeviceType
	FROM (
		SELECT TOP (@RowEnd) ROW_NUMBER() OVER (
				ORDER BY bannerid DESC
				) AS TheCount
			,BannerID
			,Category
			,[Language]
			,Lastupdate
			,Currency
			,[Message]
			,[dbo].[Aff_GetDeviceType](DeviceType) DeviceType
		FROM Banners_1 WITH (NOLOCK)
		WHERE Category = coalesce(@Category, Category)
			AND [Language] = coalesce(@Language, [Language])
			AND [ImageType] = 'Text'
			AND isnull(Currency, '') = coalesce(@Currency, Currency, '')
			AND DeviceType = @DeviceType
		) x
	WHERE x.TheCount BETWEEN @RowStart
			AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[Aff_TextSel_1] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_TextSel_1] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_TextSel_1] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TextSel_1] TO [VNTeam]
