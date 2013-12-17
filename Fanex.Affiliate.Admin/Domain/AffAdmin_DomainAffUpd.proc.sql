ALTER PROC [dbo].[AffAdmin_DomainAffUpd]  
 @DomainID int,  
 @DomainName nvarchar(50),    
 @UserID int,    
 @IP nvarchar(15)='',  
 @ErrCode int = 0 OUTPUT
AS  
/*  
Created: 20121115@ThaiTran  
Task : Update a AffDomain  
DB: DB052.Affiliate_12BET  
*/  
SET NOCOUNT ON  
--Check permission-----------------------------  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserID,@funcname='[Domain]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output
   
If @ErrCode <> 0  
 RETURN  

IF Exists(Select 1 from [AffDomain] nolock WHERE [DomainName] = @DomainName AND DomainID <> @DomainID)
BEGIN
	SELECT @ErrCode = 2001
	return
END

-----------------------------------------------  
BEGIN TRANSACTION  
UPDATE [AffDomain] with (rowlock,updlock)  
SET  
	[ModifyDate] = getdate(),  
	[DomainName] = @DomainName,                
	[Creator] = @UserID  
WHERE DomainID = @DomainID  
  
IF @@Error <> 0   
BEGIN  
	ROLLBACK TRANSACTION  
	Select @Errcode=501 -- Error occurs.Insert unsuccessfully.
	return  
END    
  
COMMIT TRANSACTION  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Update DomainID:' + dbo.Aff_ToString(@DomainID)                       
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                      
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @UserID,  
 @Typename = 'AffDomain', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffUpd] TO [vnteam]