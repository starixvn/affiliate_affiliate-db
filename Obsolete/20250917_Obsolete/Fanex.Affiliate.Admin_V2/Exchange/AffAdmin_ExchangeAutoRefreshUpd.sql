/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ExchangeAutoRefreshUpd]
    @UserId int,
    @ExchangeId int,    
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
    Created: 20110223@Viet
    Task: Enable/disable auto refresh rate (daily)
    DB: DBAFF

    Revisions:
        - 20110223@Viet: initialize SP
        - 20151031@Victor: Implement SSO for Internal Admin
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.Exchange WITH(ROWLOCK, UPDLOCK)
	SET isautorefresh = ~ ISNULL(isautorefresh, 0)
	WHERE ExchangeId = @ExchangeId

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Enable/disable auto refresh rate (daily). ExchangeId:' + dbo.Aff_ToString(@ExchangeId)
        
	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserId,        
		@TypeName = 'ExchangeRate',    
		@SPName = @SPName,
		@IP = @IP,
		@Details = @Detail
END
GO