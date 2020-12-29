/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaSize_Sel]
	@Languages		VARCHAR(MAX)
	,@Category		VARCHAR(50) = NULL
	,@SubCategory	VARCHAR(50) = NULL
	,@Currency		VARCHAR(10) = NULL
	,@ImageType		VARCHAR(10) = NULL
	,@AffType		TINYINT = NULL
	,@DeviceType	TINYINT = NULL
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
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Languages = ISNULL(@Languages, '')

	;WITH CTE_Size AS (
		SELECT Size
		FROM dbo.Banners b WITH (NOLOCK)
		WHERE ImageType <> 'Text'
			AND ',' + @Languages + ',' LIKE '%,' + b.Language + ',%'
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
		CROSS APPLY (SELECT val FROM dbo.strSplit(s.Size, 'x') WHERE [rank] = 1) h -- height
		CROSS APPLY (SELECT val FROM dbo.strSplit(s.Size, 'x') WHERE [rank] = 2) w -- weight
	ORDER BY SizeId
END
GO