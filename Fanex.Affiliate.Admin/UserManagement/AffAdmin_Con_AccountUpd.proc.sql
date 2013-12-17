ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountUpd]
	@CustID int,
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
AS

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
--DB02.BODB02 -->  DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN
--end
EXEC dbo.Aff_Con_AdminGroupUpd @CustID=@CustID,@UserID=@UserID,@GroupID=@GroupID,@Language=@Language,@ErrCode=@ErrCode output
IF @ErrCode<> 0
	RETURN 
	
BEGIN TRANSACTION
UPDATE AdminUser with (ROWLOCK, UPDLOCK) SET firstname = @FirstName, LastName = @LastName WHERE custid = @custid
IF  @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	select @ErrCode = 502
	RETURN
END
COMMIT TRANSACTION



DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'AFFILIATE UPDATE AccAdmin custid:' + dbo.Aff_ToString(@custid) + ' Name:' + dbo.Aff_ToString(@firstname) + ' '  + dbo.Aff_ToString(@lastname) + ' GroupID:' + dbo.Aff_ToString(@groupid)


EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData	






