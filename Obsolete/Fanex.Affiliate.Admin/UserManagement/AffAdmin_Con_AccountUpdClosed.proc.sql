/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountUpdClosed]
	@CustID int,
	@Closed bit,
	@UserID int,
	@Language varchar(5) = 'en-US',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT
AS

/*
	DB: DBAFF

	Revisions:
		- 20100507@VinhTrinh: update closed field in table AdminUser(instead of CustInfo)
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRANSACTION

	UPDATE dbo.AdminUser WITH (ROWLOCK, UPDLOCK) 
	SET
		Closed = @Closed,
		LoginCount = (CASE WHEN @Closed = 0 THEN 0 ELSE LoginCount END)
	WHERE custid = @CustID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = @@ERROR
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update AFFILIATE for CustID: ' + dbo.Aff_ToString(@custid) + ' closed: ' + CASE @closed WHEN 0 THEN 'open' ELSE 'closed' END

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserID,	
		@AffID = @CustID,
		@Typename = 'UserControl',	
		@SPName = @SPName ,		
		@IP = @IP,
		@Details = @Detail	
END
GO