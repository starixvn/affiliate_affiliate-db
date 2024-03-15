/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Sel]
	@TextId			INT = 0
	,@TargetId		TINYINT = 0
	,@Category		VARCHAR(50) = NULL
	,@Language		VARCHAR(50) = NULL
	,@Currency		VARCHAR(50) = NULL
	,@DeviceType	VARCHAR(10) = NULL
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Media Gallery - Text - Select

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @TargetId:
			0: All texts
			1: Member text
			2: Affiliate text
*/

BEGIN
	SET NOCOUNT ON

	IF @TextId <> 0
	BEGIN
		SELECT MediaId AS TextId, TargetId, Categories AS Category, Language, Currencies AS Currency, Message, DeviceTypes AS DeviceType
		FROM dbo.MediaGallery WITH (NOLOCK)
		WHERE MediaId = @TextId
			AND (@TargetId = 0 OR TargetId = @TargetId)
			AND ImageType = 'Text'
	END
	ELSE
	BEGIN
		DECLARE @RowStart INT, @RowEnd INT
		SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
				,@RowEnd	= @RowStart + @PageSize - 1

		SELECT @NRows = COUNT(1)
		FROM dbo.MediaGallery WITH (NOLOCK)
		WHERE (@TargetId = 0 OR TargetId = @TargetId)
			AND ImageType = 'Text'
			AND (@Category IS NULL OR Categories = @Category)
			AND (@Language IS NULL OR Language = @Language)
			AND (@Currency IS NULL OR Currencies = @Currency)
			AND (@DeviceType IS NULL OR DeviceTypes = @DeviceType)

		IF @NRows = 0
			RETURN

		SELECT MediaId AS TextId, TargetId, Categories AS Category, Language, Currencies AS Currency, Message, DeviceTypes AS DeviceType
		FROM (
			SELECT MediaId, TargetId, Categories, Language, Currencies, Message, DeviceTypes
				,ROW_NUMBER() OVER(ORDER BY MediaId DESC) AS RowNum
			FROM dbo.MediaGallery WITH (NOLOCK)
			WHERE (@TargetId = 0 OR TargetId = @TargetId)
				AND ImageType = 'Text'
				AND (@Category IS NULL OR Categories = @Category)
				AND (@Language IS NULL OR Language = @Language)
				AND (@Currency IS NULL OR Currencies = @Currency)
				AND (@DeviceType IS NULL OR DeviceTypes = @DeviceType)
		) AS r
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
END
GO