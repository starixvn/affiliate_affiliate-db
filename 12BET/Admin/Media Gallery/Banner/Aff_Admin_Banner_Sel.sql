/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Sel]
	@BannerId		INT = 0
	,@Languages		VARCHAR(MAX)
	,@Category		VARCHAR(50) = NULL
	,@SubCategory	VARCHAR(50) = NULL
	,@Currency		VARCHAR(10) = NULL
	,@ImageType		VARCHAR(10) = NULL
	,@AffType		TINYINT = NULL
	,@DeviceType	TINYINT = NULL
	,@Size			VARCHAR(20) = NULL
	,@CopiedFrom    DATETIME = NULL
	,@CopiedTo		DATETIME = NULL
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
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
		- 20200731@Percy: Change way to input Language [RedmineID: #121975]
		- 20220609@Malcolm: Get number of copies [RedmineID: #173433]
		- 20231006@Eddie: Fix to Size filter field working properly [RedmineID: #195147]
*/

BEGIN
	SET NOCOUNT ON

	IF @BannerId <> 0
	BEGIN
		SELECT BannerId,FileName,ImageType,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,UpdatedDate
		FROM dbo.Banners WITH (NOLOCK)
		WHERE BannerId = @BannerId
	END
	ELSE
	BEGIN
		SELECT @Languages = ISNULL(@Languages, '')

		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.Banners b WITH (NOLOCK)
		WHERE ImageType <> 'Text'
			AND ',' + @Languages + ',' LIKE '%,' + b.Language + ',%'
			AND (@ImageType IS NULL OR ImageType = @ImageType)
			AND (@Category IS NULL OR ',' + Categories + ',' LIKE '%,' + @Category + ',%')
			AND (@SubCategory IS NULL OR ',' + SubCategories + ',' LIKE '%,' + @SubCategory + ',%')
			AND (@Currency IS NULL OR ',' + Currencies + ',' LIKE '%,' + @Currency + ',%')
			AND (@AffType IS NULL OR ',' + AffTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @AffType) + ',%')
			AND (@DeviceType IS NULL OR ',' + DeviceTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @DeviceType) + ',%')
			AND (@Size IS NULL OR Size = @Size)

		IF @NRows = 0
			RETURN

		SELECT BannerId,FileName,ImageType,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,UpdatedDate, NumberOfCopies
		FROM (
			SELECT BannerId,FileName,ImageType,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,UpdatedDate, ISNULL(n.NumberOfCopies, 0) + ISNULL(l.NumberOfCopies, 0) AS NumberOfCopies
				,ROW_NUMBER() OVER(ORDER BY BannerId DESC) AS RowNum
			FROM dbo.Banners b WITH (NOLOCK)
				OUTER APPLY (
					SELECT COUNT(1) AS NumberOfCopies
					FROM dbo.BannerStatistics bs WITH(NOLOCK)
					WHERE bs.BannerId = b.BannerId AND bs.CopyDate >= @CopiedFrom AND bs.CopyDate < DATEADD(DAY, 1, @CopiedTo) 
						AND @CopiedFrom IS NOT NULL AND @CopiedTo IS NOT NULL
				) AS n 
				OUTER APPLY (
					SELECT SUM(bss.TotalClick) AS NumberOfCopies
					FROM dbo.BannerStatisticsSum bss WITH(NOLOCK)
					WHERE b.BannerId = bss.BannerId AND bss.CopyDate >= @CopiedFrom AND bss.CopyDate < DATEADD(DAY, 1, @CopiedTo)
						AND @CopiedFrom IS NOT NULL AND @CopiedTo IS NOT NULL
				) AS l
			WHERE ImageType <> 'Text'
				AND ',' + @Languages + ',' LIKE '%,' + b.Language + ',%'
				AND (@ImageType IS NULL OR ImageType = @ImageType)
				AND (@Category IS NULL OR ',' + Categories + ',' LIKE '%,' + @Category + ',%')
				AND (@SubCategory IS NULL OR ',' + SubCategories + ',' LIKE '%,' + @SubCategory + ',%')
				AND (@Currency IS NULL OR ',' + Currencies + ',' LIKE '%,' + @Currency + ',%')
				AND (@AffType IS NULL OR ',' + AffTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @AffType) + ',%')
				AND (@DeviceType IS NULL OR ',' + DeviceTypes + ',' LIKE '%,' + CONVERT(VARCHAR(5), @DeviceType) + ',%')
				AND (@Size IS NULL OR Size = @Size)
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO