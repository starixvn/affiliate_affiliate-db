/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffMediaChannel_Ins]
	@AffId			INT
	,@ChannelCode	VARCHAR(50)
	,@ChannelName	NVARCHAR(200)
	,@Language		VARCHAR(10) = 'en-US'
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20201215@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20201215@Percy: Initialize SP [RedmineID: #146201]
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Affiliate!'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.AffMediaChannel WITH (NOLOCK) WHERE AffId = @AffId AND ChannelCode = @ChannelCode)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'The channel already exists. Please check again.'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.AffMediaChannel (AffId, ChannelCode, ChannelName)
		VALUES (@AffId, @ChannelCode, @ChannelName)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 'ChannelCode=' + @ChannelCode + ',ChannelName=' + @ChannelName
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId
		,@AffId		= @AffId
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= @Language
END
GO