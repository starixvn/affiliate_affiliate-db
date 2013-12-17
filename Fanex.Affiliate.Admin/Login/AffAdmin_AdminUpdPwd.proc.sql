ALTER PROCEDURE [dbo].[AffAdmin_AdminUpdPwd]    
	@CustID int,  
	@OldPassword nvarchar(50)=null,  
	@NewPassword nvarchar(50),      
	@IP varchar(20),   
	@ErrCode int = 0 OUTPUT  
AS    
    
SET NOCOUNT ON    
--DB02.bodb02 --> DB052.Affiliate_AoncashUAT 
-- 20130913@Johnny : Admin change password by him/herself
--Check permission-----------------------------  

if not exists(select 1 from AdminUser with (NOLOCK)   
    where CustID = @CustID   
    and UserPwd = @OldPassword)  
BEGIN  
	Select @ErrCode = 11
	RETURN   
END  
     
declare @PwdExpiry datetime  
    
select @PwdExpiry = dateadd(dd, 30, getdate())    
UPDATE AdminUser  with (ROWLOCK, UPDLOCK)    
SET userpwd=@NewPassword, pwdexpiry=@PwdExpiry     
where custid=@CustID    
   
   
 --Write log  
declare @SPName varchar(50),@LogData nvarchar(200)    
Select @LogData = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)  
select @SPName = OBJECT_NAME(@@ProcID)  
    
EXEC [dbo].[Aff_WriteLog]   
	@Creator = @CustID,  
	@Typename = 'Password', -- refer to table LogType  
	@SPName = @SPName,  
	@Details = @LogData,  
	@IP = @IP    
    
  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_AdminUpdPwd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AdminUpdPwd] TO [vnteam]