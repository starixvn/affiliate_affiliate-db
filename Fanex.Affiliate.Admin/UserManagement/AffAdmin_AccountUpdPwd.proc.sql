ALTER PROCEDURE [dbo].[AffAdmin_AccountUpdPwd]  
	@CustID int,
	@UserID int,  
	@OldPwd nvarchar(50)=null,
	@UserPwd nvarchar(50),    
	@IP varchar(20), 
	@ErrCode int = 0 OUTPUT
AS  
  
SET NOCOUNT ON  
--DB02.bodb02 --> DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
--Check permission-----------------------------
if @OldPwd is null
BEGIN
	EXEC [dbo].[AffAdmin_Con_CheckPermission] 
		@custid=@UserID,
		@funcname='[UserControl]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output
	If @ErrCode <> 0
		RETURN
END
	
	
if not exists(select 1 from AdminUser with (NOLOCK) 
				where CustID = @CustID 
				and (case when (@OldPwd is not null and UserPwd = @OldPwd) or @OldPwd is null then 1 
						else 0 end ) = 1 )
BEGIN
	Select @ErrCode = 11
	RETURN 
END


	  
declare @PwdExpiry datetime
  
select @PwdExpiry = dateadd(dd, 30, getdate())  
UPDATE AdminUser  with (ROWLOCK, UPDLOCK)  
SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry   
where custid=@CustID  
 
 
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
  



