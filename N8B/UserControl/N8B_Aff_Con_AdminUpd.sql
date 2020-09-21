/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_AdminUpd]
	@CustID int,
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

SET NOCOUNT ON
/*
DB: DBAFFN8B-Affiliate_N8B	
Revisions:
	-- Check permission for account site: @phuc20080213
	-- DB02.BODB02 -->  DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]

*/
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
EXEC dbo.Aff_Con_AdminGroupUpd @CustID=@CustID,@UserID=@UserID,@GroupID=@GroupID,@Language=@Language,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
IF @ErrCode<> 0
	RETURN 
	
BEGIN TRANSACTION
UPDATE Affiliate_User with (ROWLOCK, UPDLOCK) SET firstname = @FirstName, LastName = @LastName WHERE custid = @custid
IF  @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	select @ErrMsg = case @Language 
						when 'E' then 'Error occurs.Update unsuccessfully.'
						when 'CS' then N'Error occurs.Update unsuccessfully.'
						when 'J' then N'Error occurs.Update unsuccessfully.'
						else N'Error occurs.Update unsuccessfully.'
					end, @ErrCode = 102
	RETURN
END
COMMIT TRANSACTION

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'AFFILIATE UPDATE AccAdmin custid:' + dbo.Aff_ToString(@custid) + ' Name:' + dbo.Aff_ToString(@firstname) + ' '  + dbo.Aff_ToString(@lastname) + ' GroupID:' + dbo.Aff_ToString(@groupid)

GO