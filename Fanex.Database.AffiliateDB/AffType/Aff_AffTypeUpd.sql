USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductUpd]    Script Date: 02/27/2013 13:19:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_AffTypeUpd]
	@Updatedby int ,
	@ID tinyint,
	@Name nvarchar(50),	
	@Description nvarchar(100)=NULL,			
	@IP nvarchar(15)='',	
	@Language varchar(5) = 'en-US',    
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
	
If(Not Exists (Select 1 from AffType (nolock) where TypeID=@ID ))
BEGIN
Select @ErrMsg = case @Language 
							when 'en-US' then 'Error! This type does not exist!'
							when 'zh-CN' then N'錯誤!這個類型不存在!'
							when 'zh-TW' then N'错误！这个类型不存在！'
							else N'Error! This type does not exist!'
						end						
						, @ErrCode = 1001
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
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeUpd] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeUpd] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeUpd] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeUpd] TO [vnteam]