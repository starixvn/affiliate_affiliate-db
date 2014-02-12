ALTER PROCEDURE [dbo].[Aff_LanguageIns]
	@Updatedby int ,
	@LanguageID varchar(8),
	@LanguageName nvarchar(50),	
	@CountryID varchar(8),		
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : Insert Language
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
	
If( Exists (Select 1 from Language (nolock) where LanguageID=@LanguageID ))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This Language is existed!' 
					when 'zh-CN' then N'錯誤!這個語言已經存在!'
					when 'zh-TW' then N'错误！这个语言已经存在！'
					else N'Error! This Language is existed!' 
				end, @ErrCode = 1001
	return
END

Declare @Order smallint

select @Order = MAX([Order]) from [Language]
INSERT INTO [Language]
           ([LanguageID]
           ,[LanguageName]
           ,[CountryID]
           ,Creator
           ,CreatedDate
		   ,[Order])
     VALUES
           (@LanguageID
           ,@LanguageName           
           ,@CountryID
           ,@Updatedby
           ,CURRENT_TIMESTAMP
		   ,@Order+1)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Language. ID= ' + dbo.Aff_ToString(@LanguageID) +	
	 '.CountryID=' + @CountryID

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Language', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
