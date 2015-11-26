ALTER PROCEDURE [dbo].[AffAdmin_AccountUpdPwd]  
	@CustID int,
	@UserID int,  
	@OldPwd nvarchar(50)=null,
	@OldSalt varchar(50)=null,
	@UserPwd nvarchar(50),   
	@UserSalt varchar(50), 
	@IP varchar(20), 
	@ErrCode int = 0 OUTPUT
AS  
  
SET NOCOUNT ON  
--DB02.bodb02 --> DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
-- 20151125@Victor: Implement SSO from Internal Admin to Affiliate Admin site
--Check permission-----------------------------
DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

if @OldPwd is null
BEGIN
	EXEC [dbo].[AffAdmin_Con_CheckPermission] 
		@LicenseeID = @LicenseeID,
		@custid=@UserID,
		@funcname='[UserControl]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output
	If @ErrCode <> 0
		RETURN
END
	
	
if not exists(	select 1 from dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID) 
				where (case when (@OldPwd is not null and UserPwd = @OldPwd) or @OldPwd is null then 1 else 0 end ) = 1 
					AND (case when (@OldSalt is not null and UserSalt = @OldSalt) or @OldSalt is null then 1 else 0 end ) = 1)
BEGIN
	Select @ErrCode = 11
	RETURN 
END

EXEC DBLIC.bodb_licensee.dbo.AffAdmin_ITAdminUser_Update @UserID = @CustID, @UserPwd = @UserPwd, @UserSalt = @UserSalt
 
 --Write log
declare @SPName varchar(50),@LogData nvarchar(200)  
Select @LogData = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)
select @SPName = OBJECT_NAME(@@ProcID)
  
EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP  
  



