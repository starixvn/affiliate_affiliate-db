ALTER PROCEDURE [dbo].[AffAdmin_AdminUpdPwd]    
    @CustID int,  
    @OldPassword nvarchar(50),  
    @NewPassword nvarchar(50),      
    @IP varchar(20),   
    @ErrCode int = 0 OUTPUT  
AS    
    
SET NOCOUNT ON    
--DB02.bodb02 --> DB052.Affiliate_AoncashUAT 
--20130913@Johnny: Admin change password by him/herself
--20151204@Francis: Revise sp to support AFF Admin User SSO
--Check permission-----------------------------  

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'


IF not exists(	select 1 from dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID) 
				where (case when (@OldPassword is not null and UserPwd = @OldPassword) or @OldPassword is null then 1 else 0 end ) = 1 )
BEGIN
	Select @ErrCode = 11
	RETURN 
END
     
EXEC DBLIC.bodb_licensee.dbo.AffAdmin_ITAdminUser_Update @UserID = @CustID, @UserPwd = @NewPassword
   
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
GRANT EXECUTE ON [dbo].[AffAdmin_AdminUpdPwd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AdminUpdPwd] TO [vnteam] AS [dbo]