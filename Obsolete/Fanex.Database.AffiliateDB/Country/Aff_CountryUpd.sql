USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountryUpd]    Script Date: 02/28/2013 13:36:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_CountryUpd]
	@Updatedby int ,
	@CountryID nvarchar(6),
	@CountryName nvarchar(255),	
	@Description nvarchar(100)=NULL,	
	@Icon nvarchar(100)=NULL,
	@DisplayOrder smallint=1,
	@IsEnabled bit=1,
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Country
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
	
If(Not Exists (Select 1 from Country (nolock) where CountryID=@CountryID ))
BEGIN
Select @ErrMsg = case @Language 
							when 'en-US' then 'Error! This country does not exist!' 
							when 'zh-CN' then N'錯誤!這個國家不存在!'
							when 'zh-TW' then N'错误！这个国家不存在！'
							else N'Error! This country does not exist!' 
						end, @ErrCode = 1001
	return
END
update Country with (rowlock,updlock)
Set CountryName=@CountryName, [Description]=@Description,
Icon=coalesce(@Icon,Icon), 
DisplayOrder=coalesce(DisplayOrder,DisplayOrder),
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
