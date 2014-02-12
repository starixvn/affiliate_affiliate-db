USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageUpd]    Script Date: 02/18/2013 09:30:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_LanguageUpd]
	@Updatedby int ,
	@LanguageID varchar(8),
	@LanguageName nvarchar(255),	
	@CountryID varchar(8),			
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Language
DB: DB052.Affiliate_ZZun
Original:

Revisions:
	20130218 - Joseph: Change LanguageID data type
Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error CountryID.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[Language]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN
	
If(Not Exists (Select 1 from Language (nolock) where LanguageID=@LanguageID ))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This Language does not exist!' 
					when 'zh-CN' then N'錯誤!這個語言不存在!'
					when 'zh-TW' then N'错误！这个语言不存在！'
					else N'Error! This Language does not exist!' 
				end, @ErrCode = 1001
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
