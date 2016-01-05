ALTER PROCEDURE [dbo].[AffAdmin_CountryIns]
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
Task : Insert Country
DB: DB052.Affiliate_MYM
Original:

Revisions:
-20151221@Francis: Support SSO

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
    
-- Check new country has existed in db
IF EXISTS (
    SELECT 1
    FROM Country
    WHERE CountryID=@CountryID
 )
BEGIN
    SELECT @ErrCode = 400, @ErrMsg='New country has existed.'
    RETURN
END

INSERT INTO [dbo].[Country]
           ([CountryID]
           ,[CountryName]
           ,[Description]
           ,[Icon]
           ,[DisplayOrder]
           ,[IsEnabled])
     VALUES
           (@CountryID
           ,@CountryName
           ,@Description
           ,@Icon
           ,@DisplayOrder
           ,@IsEnabled)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Country. ID= ' + @CountryID +
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
