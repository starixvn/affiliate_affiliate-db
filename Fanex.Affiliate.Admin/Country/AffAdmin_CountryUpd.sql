ALTER PROCEDURE [dbo].[AffAdmin_CountryUpd]
    @Updatedby int ,
    @CountryID nvarchar(6),
    @CountryName nvarchar(255),    
    @Description nvarchar(100)=NULL,    
    @Icon nvarchar(100)=NULL,
    @DisplayOrder smallint=1,
    @IsEnabled bit=1,
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Country
DB: DB052.Affiliate_MYM
Original:

Revisions:
-20151221@Francis: Suppot SSO

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
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
    
If(Not Exists (Select 1 from Country (nolock) where CountryID=@CountryID ))
BEGIN
Select @ErrMsg = N'Error! This country does not exist!', @ErrCode = 1001
    return
END
update Country with (rowlock,updlock)
Set CountryName=@CountryName, [Description]=@Description,
Icon=coalesce(@Icon,Icon), 
DisplayOrder=coalesce(@DisplayOrder,DisplayOrder),
IsEnabled =  @IsEnabled
where CountryID=@CountryID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Country. ID= ' + dbo.Aff_ToString(@CountryID) +
     '. Description=' + isnull(@Description,'')

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Country', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO


