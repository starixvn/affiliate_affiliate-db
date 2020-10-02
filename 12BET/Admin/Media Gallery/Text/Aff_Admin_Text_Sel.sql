/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Sel]
	@TextId		INT = 0
	,@Category		VARCHAR(50) = NULL
	,@Languages		VARCHAR(MAX)
	,@Currency		VARCHAR(50) = NULL
	,@DeviceType	VARCHAR(10) = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Text - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
		- 20200731@Percy: Change way to input Language [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	IF @TextId <> 0
	BEGIN
		SELECT BannerId AS TextId, Categories AS Category, Language, Currencies AS Currency, Message, DeviceTypes AS DeviceType
		FROM dbo.Banners WITH (NOLOCK)
		WHERE BannerId = @TextId
	END
	ELSE
	BEGIN
		SELECT @Languages = ISNULL(@Languages, '')
		
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.Banners b WITH (NOLOCK)
		WHERE ImageType = 'Text'
			AND ',' + @Languages + ',' LIKE '%,' + b.Language + ',%'
			AND (@Category IS NULL OR Categories = @Category)
			AND (@Currency IS NULL OR Currencies = @Currency)
			AND (@DeviceType IS NULL OR DeviceTypes = @DeviceType)

		IF @NRows = 0
			RETURN

		SELECT BannerId AS TextId, Categories AS Category, Language, Currencies AS Currency, Message, DeviceTypes AS DeviceType
		FROM (
			SELECT BannerId, Categories, Language, Currencies, Message, DeviceTypes
				,ROW_NUMBER() OVER(ORDER BY BannerId DESC) AS RowNum
			FROM dbo.Banners b WITH (NOLOCK)
			WHERE ImageType = 'Text'
				AND ',' + @Languages + ',' LIKE '%,' + b.Language + ',%'
				AND (@Category IS NULL OR Categories = @Category)
				AND (@Currency IS NULL OR Currencies = @Currency)
				AND (@DeviceType IS NULL OR DeviceTypes = @DeviceType)
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO