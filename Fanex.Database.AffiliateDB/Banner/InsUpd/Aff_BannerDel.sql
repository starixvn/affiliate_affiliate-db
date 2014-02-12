ALTER PROCEDURE [dbo].[Aff_BannerDel]
	@ListBannerID varchar(4000)=null,
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Delete affiliate Banners by list of ids
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
• @ListBannerID : list of banner ids need to delete separated by a comma
• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[Media]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
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
inner join banners b with (nolock) on b.bannerid = val and COALESCE(b.totalrequest,0) = 0 

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
						end
					, @ErrCode = 102
	        return      
        END    
--Check UserID is valid
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))
begin
	 Select @ErrMsg = case @Language 
							when 'en-US' then 'Sorry, Admin id is invalid. Please recheck it again.' 
							when 'zh-CN' then N'抱歉, 管理員ID是無效的.請重新確認.'
							when 'zh-TW' then N'抱歉，管理员ID是无效的，请重新确认。'
							else N'Sorry, Admin id is invalid. Please recheck it again.' 
						end,								 
					@ErrCode = 103
	        return
end

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




GO
GRANT EXECUTE ON [dbo].[Aff_BannerDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerDel] TO [vnteam]
GO
