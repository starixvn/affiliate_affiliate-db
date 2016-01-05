ALTER PROCEDURE [dbo].[AffAdmin_LanguageUpd]
    @Updatedby int ,
    @LanguageID varchar(8),
    @LanguageName nvarchar(50),    
    @CountryID varchar(8),            
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Language
DB: DB052.Affiliate_MYM
Original:

Revisions:
-20151221@Francis: Support SSO

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error CountryID.
*/
SET NOCOUNT ON

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

EXEC [dbo].[Aff_Con_CheckPermission]
	 @LicenseeID = @LicenseeID,
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from Language (nolock) where LanguageID=@LanguageID ))
BEGIN
Select @ErrMsg = N'Error! This Language does not exist!', @ErrCode = 1001
    return
END
update Language with (rowlock,updlock)
Set LanguageName=@LanguageName, [CountryID]=@CountryID
where LanguageID=@LanguageID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Language. ID= ' + @LanguageID +     
    '.LanguageName=' + @LanguageName + 
     '.CountryID=' + @CountryID

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Language', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end