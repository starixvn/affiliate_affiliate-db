CREATE PROCEDURE [dbo].[AffAdmin_BannerUpd]
	@BannerID int ,
	@Content nvarchar(4000)=null,
	@Category smallint=null,
	@Language varchar(8)='en-US',
	@ImageType smallint=null,
	@Size varchar(50)=null,
	@Currency smallint=null,
    @BannerType tinyint,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT
AS
/*
Created: 20090331@DungTong
Task :Update affiliate Banners
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:

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
if @Size = ''
	set @Size = null
if(@Size is not null and @BannerType in(1,2) and not exists(select 1 from BannerTypes (nolock) where Type='Size' and Value=@Size))
Begin
	    Insert into  BannerTypes (type,value,Displayorder) values('Size',@Size,1)	    
end

declare @SizeID smallint
if(@BannerType in(1,2))
begin
  select @SizeID=TypeID from BannerTypes (nolock) where Type='Size' and Value=@Size  
end


UPDATE Banners with(rowlock,updlock)
SET 	
	LastUpdate = getdate(),
	UpdatedBy=@UserID,
	[Content]=coalesce(@Content,Content),
	Category=coalesce(@Category,Category),
	Language=coalesce(@Language,Language),
	ImageType=coalesce(@ImageType,ImageType),
	Size=coalesce(@SizeID,Size),
	Currency=coalesce(@Currency,Currency),
    Type=coalesce(@BannerType,Type)
WHERE BannerID=@BannerID
IF @@Error <> 0 
BEGIN
	Select @Errcode=502
	return
END 
	Select @Errcode=0

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) 
                  +  ' Content:' + dbo.Aff_ToString(@Content)
                  +  ' Category:' + dbo.Aff_ToString(@Category)
                  +  ' Language:' + dbo.Aff_ToString(@Language)
                  +  ' ImageType:' + dbo.Aff_ToString(@ImageType)
                  +  ' Size:' + dbo.Aff_ToString(@Size)
                  +  ' Currency:' + dbo.Aff_ToString(@Currency)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP

GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_BannerUpd] TO [vnteam]