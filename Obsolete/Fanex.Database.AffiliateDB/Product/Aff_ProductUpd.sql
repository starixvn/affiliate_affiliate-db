USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductUpd]    Script Date: 02/28/2013 12:58:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_ProductUpd]
	@Updatedby int ,
	@ProductID tinyint,
	@ProductName nvarchar(50),	
	@Description nvarchar(100)=NULL,		
	@BettypeList nvarchar(255),
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Product
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
	
If(Not Exists (Select 1 from Product (nolock) where ProductID=@ProductID ))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This Product does not exist!' 
					when 'zh-CN' then N'錯誤!這個產品不存在!'
					when 'zh-TW' then N'错误！这个产品不存在！'
					else N'Error! This Product does not exist!' 
				end, @ErrCode = 1001
	return
END
update Product with (rowlock,updlock)
Set ProductName=@ProductName, [Description]=@Description,
BettypeList =  @BettypeList
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
