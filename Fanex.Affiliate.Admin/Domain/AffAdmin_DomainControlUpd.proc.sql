ALTER PROCEDURE [dbo].[AffAdmin_DomainControlUpd]  
 @ID int,  
 @AffDomainID int,  
 @MemberDomainID int,  
 @CountryID nvarchar(10),  
 @Status bit = 1,   
 @UserID int,   
 @IP nvarchar(15)='',  
 @Language varchar(5)= 'en-US',   
 @ErrCode int = 0 OUTPUT
AS  
/*  
Created: 20121115@Johnny.Trinh  
Task : Update Domain control info  
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
If Exists(select 1 from AffDomainControl nolock where ID <> @ID and AffDomainID = @AffDomainID and [MemberDomainID] = @MemberDomainID and CountryID = @CountryID)  
Begin  
	select @ErrCode = 2020
	return  
End  
  
BEGIN TRANSACTION  
Update [AffDomainControl] with (rowlock, updlock)  
set  
    [AffDomainID] = @AffDomainID  
 ,[MemberDomainID]= @MemberDomainID  
    ,[CountryID]  = @CountryID  
    ,[ModifyDate] = current_timestamp  
    ,[Status]  = @Status  
 ,[Creator]  = @UserID  
where ID = @ID  
  
IF @@ERROR <> 0  
BEGIN  
	ROLLBACK TRANSACTION  
	Select @ErrCode = 502  
	return  
END  
  
COMMIT TRANSACTION  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Update AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                       
                    + ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)                      
     + ' CountryID:' + dbo.Aff_ToString(@CountryID)                      
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @UserID,  
 @Typename = 'AffDomainControl', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
  
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainControlUpd] TO [vnteam]