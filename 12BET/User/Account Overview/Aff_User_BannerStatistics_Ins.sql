/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_BannerStatistics_Ins]
	@AffId		INT
	,@BannerId  INT
	,@ErrCode   INT = 0 OUTPUT  
	,@ErrMsg    NVARCHAR(4000) = '' OUTPUT  
AS

/*
	Created: 20220609@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: User Site - Account Overview - Media gallery - Click to copy banner

	Revisions:
		- 20220609@Malcolm: Initialize SP [RedmineID: #173433]

*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		INSERT INTO dbo.BannerStatistics (AffId, BannerId)
		VALUES (@AffId, @BannerId)
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
END
GO