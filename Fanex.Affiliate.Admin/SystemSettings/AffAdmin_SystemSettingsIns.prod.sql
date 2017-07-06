/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

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
	Task:
	DB: DBAFF
	Original:

	Revisions:
		- 20140122@Bobby: add checking enviroment
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS (SELECT 1 FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = @key AND [Type] = @Type AND (@Environment IS NULL OR Environment=@Environment))
	BEGIN
		SELECT
			@ErrCode = 1001,
			@ErrMsg = CASE @Language
						WHEN 'en-US' THEN 'Error! This setting key is existed!'
						WHEN 'zh-CN' THEN N'錯誤!這個設定金鑰已經存在!'
						WHEN 'zh-TW' THEN N'错误！这个设置金者已经存在！'
						ELSE N'Error! This setting key is existed!'
					END
		RETURN
	END

	BEGIN TRANSACTION

	IF @Type IN ('CustomerDomainList', 'AffiliateLinkDomainList', 'BannerDomainList')
	BEGIN
		INSERT INTO [dbo].[SystemSettings]
		(
			[SName]
			,[SValue]
			,[Type]
			,[Description]
		)
		SELECT
			ResourceKey
			,@Value
			,@Type
			,@Description
		FROM
		(
			SELECT DISTINCT ResourceKey FROM RefResources WITH(NOLOCK) WHERE RefID = 'CountryCode'
		) a

		SELECT @ID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[SystemSettings]
		(
			[SName]
			,[SValue]
			,[Type]
			,[Description]
			,[Environment]
		)
		VALUES
		(
			@Key
			,@Value
			,@Type
			,@Description
			,@Environment
		)

		SELECT @ID = SCOPE_IDENTITY()
	END

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Add new Sytem Setting. ID=' + dbo.Aff_ToString(@ID)
					+ '.Key=' + dbo.Aff_ToString(@Key)
					+ '.Value=' + ISNULL(@Value, '')
					+ '.Type=' + dbo.Aff_ToString(@Type)
					+ '. Description=' + ISNULL(@Description, '')
					+ '.Environment=' + ISNULL(@Environment, '')

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @Updatedby
		,@AffID = @Updatedby
		,@Typename = 'SystemSettings' -- refer to table LogType
		,@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO