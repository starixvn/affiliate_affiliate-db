ALTER PROCEDURE [dbo].[Aff_ProductIns]
	@Updatedby int ,
	@ProductName nvarchar(50),	
	@Description nvarchar(100)=NULL,	
	@BettypeList nvarchar(255)=NULL,	
	@IP nvarchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : Insert Product
DB: DB052.Affiliate_ZZun
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
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
           ,[BettypeList])
     VALUES
           (
           @ProductName
           ,@Description
           ,@Updatedby
           ,CURRENT_TIMESTAMP
           ,@BettypeList)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Product. ID= ' + dbo.Aff_ToString(SCOPE_IDENTITY()) +	
	 '.BettypeList=' + @BettypeList

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Product', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
