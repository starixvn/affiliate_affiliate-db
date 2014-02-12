USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_TextDel]    Script Date: 01/30/2013 10:27:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextDel_xpre    Script Date: 4/3/2012 3:07:15 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextDel    Script Date: 2/24/2012 10:17:35 AM ******/

ALTER PROCEDURE [dbo].[Aff_TextDel]
	@ListBannerID varchar(4000)=null,
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
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
--Check UserID is valid
if(not exists(select 1 from dbo.AdminUser (nolock) where custid=@UserID))
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