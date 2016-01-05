ALTER PROCEDURE [dbo].[AffAdmin_AffTypeUpd]
    @Updatedby int ,
    @ID tinyint,
    @Name nvarchar(50),    
    @Description nvarchar(100)=NULL,            
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Product
DB: DB052.Affiliate_MYM
Original:

Revisions:

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
    
If(Not Exists (Select 1 from AffType (nolock) where TypeID=@ID ))
BEGIN
Select @ErrMsg = N'Error! This type does not exist!', @ErrCode = 1001
    return
END
update AffType with (rowlock,updlock)
Set Name=@Name, [Description]=@Description
where TypeID=@ID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update afftype. ID= ' + dbo.Aff_ToString(@ID) 
     

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'AffType', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end