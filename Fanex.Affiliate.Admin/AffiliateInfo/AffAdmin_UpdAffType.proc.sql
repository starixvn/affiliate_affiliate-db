ALTER PROCEDURE [dbo].[AffAdmin_UpdAffType]
	@UserId int ,  
	@AffID int,  
	@AffType tinyint,    
	@IP nvarchar(15)='',   
	@Language varchar(5)= 'en-US',   
	@ErrCode int = 0 OUTPUT 
as  
begin   
  
SET NOCOUNT ON  
  
EXEC dbo.Aff_CheckPermissionOnAff     
	@custid=@UserId,    
	@AffId=@AffId,    
	@ErrCode=@ErrCode output  
   
If @ErrCode <> 0  
 RETURN  
   
If(Not Exists (Select 1 from AffInfo (nolock) where AffID=@AffID ))  
BEGIN  
	Select @ErrCode = 13  --'Error! This affiliate does not exist!'
	return  
END  

update AffInfo with (rowlock,updlock)  
Set AffType=@AffType  
where AffID=@AffID  
  
  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Update AffInfo AffType. AffID= ' + dbo.Aff_ToString(@AffID)   
    +'AffType= ' + dbo.Aff_ToString(@AffType)   
    
  
EXEC [dbo].[Aff_WriteLog]   
	@Creator = @UserId,  
	@AffID = @AffID,  
	@Typename = 'AffInfo', -- refer to table LogType  
	@SPName = @SPName,  
	@Details = @Detail,  
	@IP = @IP  
   
end  
  
     
GO
GRANT EXECUTE ON [dbo].[AffAdmin_UpdAffType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UpdAffType] TO [vnteam]