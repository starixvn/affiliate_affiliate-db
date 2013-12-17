Alter PROC [dbo].[AffAdmin_DomainAffIns]  
 @DomainID int OUTPUT,  
 @DomainName nvarchar(50),    
 @UserID int,    
 @IP nvarchar(15)='',  
 @ErrCode int = 0 OUTPUT
AS  
/*  
Created: 20121115@ThaiTran  
Task : Add a new AffDomain  
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
-----------------------------------------------  
If Exists(select 1 from [AffDomain] nolock where DomainName = @DomainName)  
Begin  
 select @ErrCode = 2001--Domain has been existed
 return  
End  
  
declare @CreatedDate datetime  
select @CreatedDate=Current_Timestamp  
  
BEGIN TRANSACTION  
INSERT INTO [AffDomain]  
   (   
        [DomainName]  
       ,[CreateDate]  
       ,[ModifyDate]  
       ,[Creator]         
 )  
 VALUES  
 (           
  @DomainName,      
  @CreatedDate,  
  @CreatedDate,  
        @UserID    
 )  
IF @@ERROR <> 0  
BEGIN  
	ROLLBACK TRANSACTION  
	Select @ErrCode = 501
	return  
END  
  
SELECT @DomainID = @@IDENTITY  
  
COMMIT TRANSACTION  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Create DomainID:' + dbo.Aff_ToString(@DomainID)                       
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                      
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @UserID,  
 @Typename = 'AffDomain', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
  
  
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffIns] TO [vnteam]