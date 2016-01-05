ALTER PROCEDURE [dbo].[AffAdmin_ProductIns]
    @Updatedby int ,
    @ProductName nvarchar(50),    
    @Description nvarchar(100)=NULL,    
    @BettypeList nvarchar(255)=NULL,    
    @API_ProductID int=NULL,    
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : Insert Product
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

INSERT INTO [Product]
           (
           [ProductName]
           ,[Description]
           ,[Creator]
           ,[CreatedDate]
           ,[BettypeList]
           ,[API_ProductID]
           )
     VALUES
           (
           @ProductName
           ,@Description
           ,@Updatedby
           ,CURRENT_TIMESTAMP
           ,@BettypeList
           ,@API_ProductID
           )


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Product. ID= ' + dbo.Aff_ToString(SCOPE_IDENTITY()) +    
     '.BettypeList=' + @BettypeList +
     '.API_ProductID=' + dbo.Aff_ToString(@API_ProductID)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Product', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end