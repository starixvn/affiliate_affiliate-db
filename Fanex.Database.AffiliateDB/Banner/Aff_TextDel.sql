/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[Aff_TextDel]
	@ListBannerID varchar(4000)=null,
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*  
	Created:
	Task:
	DB: DBAFF
	Original:  
  
	Revisions:  
		- 20180205@Percy: Remove check permission and UserId [RedmineID: #90545]
*/

BEGIN
	SET NOCOUNT ON

	--Check list of bannerID
	if(@ListBannerID is null)
	begin
		Select @ErrMsg = case @Language 
								when 'en-US' then 'Invalid Banner ID!' 
								when 'zh-CN' then N'無效的廣告ID!'
								when 'zh-TW' then N'无效的广告ID！'
								else N'Invalid Banner ID!' 
							end, @ErrCode = 101	
		return
	end	

	declare @bannerIDTable table(bannerid int)

	insert into @bannerIDTable
	select distinct val from dbo.strsplit(@ListBannerID,',')

	declare @count int,@countDB int
	select @count=count(1) from  @bannerIDTable
	select @countDB=count(1)
	from Banners a (nolock)
		inner join  @bannerIDTable t on a.BannerID=t.bannerid
    
	if (@count <> @countDB)
	BEGIN
			Select @ErrMsg = case @Language 
						when 'en-US' then 'Sorry, your input banner id is invalid. Please recheck it again.' 
						when 'zh-CN' then N'抱歉,您輸入的廣告ID是無效的.請重新確認.'
						when 'zh-TW' then N'抱歉，您输入的广告ID是无效的，请重新确认。'
						else N'Sorry, your input banner id is invalid. Please recheck it again.' 
					end,								 
				@ErrCode = 102
		return      
	END

	Delete Banners with(rowlock)
	WHERE BannerID in (select bannerid from  @bannerIDTable)

	IF @@ERROR <> 0
	BEGIN
	
		Select @ErrMsg = case @Language 
								when 'en-US' then 'Error! Banner unsuccessfully deleted!' 
								when 'zh-CN' then N'錯誤!廣告刪除不成功'
								when 'zh-TW' then N'错误！广告删除不成功'
								else N'Error! Banner unsuccessfully deleted!' 
							end, @ErrCode = 1001
		return
	END

	--Write log
	declare @SPName varchar(50), @Detail nvarchar(4000) 
	select @SPName = OBJECT_NAME(@@ProcID)
	select @Detail = 'Delete Banners BannerIDList:' + dbo.Aff_ToString(@ListBannerID)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'Banner', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO