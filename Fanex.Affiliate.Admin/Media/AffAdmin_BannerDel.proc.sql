CREATE PROCEDURE [dbo].[AffAdmin_BannerDel]
	@ListBannerID varchar(4000),
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
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
EXEC [dbo].[AffAdmin_Con_CheckPermission]
	@custid=@UserID,@funcname='[Media]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
--Check list of bannerID
if(@ListBannerID is null)
begin
	Select @ErrCode = 300	
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
			 Select @ErrCode = 301
	        return      
        END    
--Check UserID is valid
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))
begin
	 Select @ErrCode = 302
	        return
end

Delete Banners with(rowlock)
WHERE BannerID in (select bannerid from  @bannerIDTable)

IF @@ERROR <> 0
BEGIN
	
	Select @ErrCode = 303
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
GRANT EXECUTE ON [dbo].[AffAdmin_BannerDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_BannerDel] TO [vnteam]