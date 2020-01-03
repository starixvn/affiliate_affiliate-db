/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Sel]
	@TextId			INT = 0
	,@Category		VARCHAR(50) = NULL
	,@Language		VARCHAR(50) = NULL
	,@Currency		VARCHAR(50) = NULL
	,@DeviceType	TINYINT = 0
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
*/

BEGIN
	SET NOCOUNT ON

	IF @TextId <> 0
	BEGIN
		SELECT BannerId AS TextId, Category, Language, Currency, Message, DeviceType
		FROM dbo.Banners_1 WITH (NOLOCK)
		WHERE BannerId = @TextId
	END
	ELSE
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.Banners_1 WITH (NOLOCK)
		WHERE ImageType = 'Text'
			AND (@Category IS NULL OR Category = @Category)
			AND (@Language IS NULL OR Language = @Language)
			AND (@Currency IS NULL OR Currency = @Currency)
			AND (@DeviceType IS NULL OR ISNULL(DeviceType, 0) = @DeviceType)

		IF @NRows = 0
			RETURN

		SELECT BannerId AS TextId, Category, Language, Currency, Message, DeviceType
		FROM (
			SELECT BannerId, Category, Language, Currency, Message, DeviceType
				,ROW_NUMBER() OVER(ORDER BY BannerId DESC) AS RowNum
			FROM dbo.Banners_1 WITH (NOLOCK)
			WHERE ImageType = 'Text'
				AND (@Category IS NULL OR Category = @Category)
				AND (@Language IS NULL OR Language = @Language)
				AND (@Currency IS NULL OR Currency = @Currency)
				AND (@DeviceType IS NULL OR ISNULL(DeviceType, 0) = @DeviceType)
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO