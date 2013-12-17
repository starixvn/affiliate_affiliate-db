ALTER Procedure [dbo].[AffAdmin_DomainControlDel]  
 @Id int,  
 @UserID int,   
 @IP nvarchar(15)='',  
 @ErrCode int = 0 OUTPUT
AS  
/*  
Created: 20121115@Johnny.Trinh  
Task : Add a new AffDomainControl  
DB: DB052.Affiliate  
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
declare @AffDomainID int, @MemberDomainID int, @CountryID nvarchar(10)  
  
select @AffDomainID = AffDomainID, @MemberDomainID = [MemberDomainID], @CountryID = CountryID  
from [AffDomainControl]  
where Id = @Id  
  
delete [AffDomainControl]  
where Id = @Id  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Delete AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                       
                    + ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)                      
     + ' CountryID:' + dbo.Aff_ToString(@CountryID)                      
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @UserID,  
 @Typename = 'AffDomainControl', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  

  
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainControlDel] TO [vnteam]