ALTER PROCEDURE [dbo].[AffAdmin_DomainAffDel]  
	@DomainID int OUTPUT,      
	@UserID int,   
	@IP nvarchar(15)='',  
	@ErrCode int = 0 OUTPUT 
AS  
/*  
Created: 20121115@ThaiTran  
Task : Del a AffDomain  
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

DECLARE @DomainName nvarchar(50)

-----------------------------------------------  
If Exists(select 1 from AffDomainControl nolock where [AffDomainID] = @DomainID)  
Begin  
 select @ErrCode = 2002--Domain has been used
 return  
End  

Select @DomainName = DomainName from [AffDomain] nolock where DomainID = @DomainID --Store Domain name to write log

delete  [AffDomain]  
where DomainID = @DomainID  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Delete DomainID:' + dbo.Aff_ToString(@DomainID)                       
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                           
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @UserID,  
 @Typename = 'AffDomain', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
  
    
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffDel] TO [vnteam]