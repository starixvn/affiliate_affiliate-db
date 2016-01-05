ALTER PROCEDURE [dbo].[AffAdmin_ProductUpd]
    @Updatedby int ,
    @ProductID tinyint,
    @ProductName varchar(50),    
    @Description nvarchar(100)=NULL,        
    @BettypeList nvarchar(255)=NULL,
    @API_ProductID int = NULL,
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
    
If(Not Exists (Select 1 from Product (nolock) where ProductID=@ProductID ))
BEGIN
Select @ErrMsg = N'Error! This Product does not exist!', @ErrCode = 1001
    return
END
update Product with (rowlock,updlock)
Set ProductName=@ProductName, 
[Description]=@Description,
BettypeList =  @BettypeList,
API_ProductID = ISNULL(@API_ProductID, NULL)
where ProductID=@ProductID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Product. ID= ' + dbo.Aff_ToString(@ProductID) +     
     '.BettypeList=' + @BettypeList

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Product', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end