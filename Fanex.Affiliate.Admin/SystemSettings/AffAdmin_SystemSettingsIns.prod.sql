ALTER PROCEDURE [dbo].[AffAdmin_SystemSettingsIns] 
	@LicenseeID INT
	,@Updatedby INT
	,@Key VARCHAR(50)
	,@Value NVARCHAR(max)
	,@Type VARCHAR(50) = ''
	,@Description NVARCHAR(100) = NULL
	,@Environment NVARCHAR(100) = NULL
	,@IP NVARCHAR(15) = ''
	,@ID INT = 0 OUTPUT
	,@Language VARCHAR(5) = 'en-US'
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision] 
	- 20140122@Bobby: add checking enviroment
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

				EXEC [dbo].[Aff_Con_CheckPermission] @LicenseeID = @LicenseeID
		,@custid = @Updatedby
		,@funcname = '[SystemSettings]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 RETURN

	IF (
			EXISTS (
				SELECT 1
				FROM SystemSettings(NOLOCK)
				WHERE SName = @key 
					AND [Type] = @Type
					AND (@Environment IS NULL OR Environment=@Environment)
				)
			)
	BEGIN
		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Error! This setting key is existed!'
				WHEN 'zh-CN' THEN N'錯誤!這個設定金鑰已經存在!'
				WHEN 'zh-TW' THEN N'错误！这个设置金者已经存在！'
				ELSE N'Error! This setting key is existed!'
				END
			,@ErrCode = 1001

		RETURN
	END

	IF (@Type IN ('CustomerDomainList', 'AffiliateLinkDomainList', 'BannerDomainList'))
	BEGIN
		INSERT INTO [dbo].[SystemSettings] (
			[SName]
			,[SValue]
			,[Type]
			,[Description]
			)
		SELECT ResourceKey
			,@Value
			,@Type
			,@Description
		FROM (
			SELECT DISTINCT ResourceKey
			FROM RefResources(NOLOCK)
			WHERE RefID = 'CountryCode'
			) a

		SELECT @ID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[SystemSettings] (
			[SName]
			,[SValue]
			,[Type]
			,[Description]
			,[Environment]
			)
		VALUES (
			@Key
			,@Value
			,@Type
			,@Description
			,@Environment
			)

		SELECT @ID = SCOPE_IDENTITY()
	END

	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Add new Sytem Setting. ID=' + dbo.Aff_ToString(@ID) + '.Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value, '') + '.Type=' + dbo.Aff_ToString(@Type) + '. Description=' + isnull(@Description, '') + '.Environment=' + isnull(@Environment, '')

	EXEC [dbo].[Aff_WriteLog] @Creator = @Updatedby
		,@AffID = @Updatedby
		,@Typename = 'SystemSettings'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END

GRANT EXECUTE ON [dbo].[AffAdmin_DeductionTypeSel] TO [bodbAdminNet]