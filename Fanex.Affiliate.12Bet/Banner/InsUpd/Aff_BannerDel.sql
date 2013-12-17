
ALTER PROCEDURE [dbo].[Aff_BannerDel]
	@ListBannerID varchar(4000)=null,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Delete affiliate Banners by list of ids
DB: DB052.Affiliate_12BET
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
	Select @ErrMsg = 'Invalid Banner ID!', @ErrCode = 101	
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
			 Select @ErrMsg ='Sorry, your input banner id is invalid. Please recheck it again.',								 
					@ErrCode = 102
			return      
		END    
--Check UserID is valid
if(not exists(select 1 from Affiliate_User (nolock) where custid=@UserID))
begin
	 Select @ErrMsg ='Sorry, Admin id is invalid. Please recheck it again.',								 
					@ErrCode = 103
			return
end

BEGIN TRANSACTION

--Get the sizes and the count use in Banners table
Declare @SizeTable Table(Size varchar(50), CountUse int)

Insert Into @SizeTable
Select	bb.Size, bb.CountUse
From	(Select b.Size, COUNT(b.Size) as CountUse
		From Banners b
		Group By b.Size) bb
Where	bb.Size in (Select Distinct n.Size
					From Banners n
					Where n.BannerID in (Select bannerid From  @bannerIDTable))
And		bb.CountUse=1

--Delete these sizes which have the count use = 1
Delete From BannerTypes 
Where Type='Size' and Value in (Select Size From @SizeTable)
IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = N'Error! Banner unsuccessfully deleted!', @ErrCode = 1001
	return
END

--Delete banners
Delete Banners with(rowlock)
WHERE BannerID in (select bannerid from  @bannerIDTable)

IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = N'Error! Banner unsuccessfully deleted!', @ErrCode = 1001
	return
END

COMMIT TRANSACTION

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
