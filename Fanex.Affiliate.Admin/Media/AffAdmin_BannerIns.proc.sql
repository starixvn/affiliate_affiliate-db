CREATE PROCEDURE [dbo].[AffAdmin_BannerIns]
	@BannerID int OUTPUT,
	@Content nvarchar(4000),	
	@Category smallint,
	@ImageType smallint, 
	@Currency smallint,
	@Size varchar(50)=NULL,
    @BannerType tinyint =1, /*0: Text, 1: Normal banner, 2: Media banner */
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(8)='en-US',
	@ErrCode int = 0 OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Add a new Banner
DB: DB052.Affiliate_ZZun
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
EXEC [dbo].[AffAdmin_Con_CheckPermission]	@custid = @UserID,
											@funcname = '[Media]',
											@System = 'AFFILIATE',
											@ErrCode = @ErrCode OUTPUT
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
declare @CreatedDate datetime
SELECT
	@CreatedDate = CURRENT_TIMESTAMP
if @Size = ''
SET @Size = NULL

if(@Size Is Not NULL AND @BannerType in (1,2) and not exists (SELECT
	1
FROM BannerTypes(nolock)
WHERE Type = 'Size' AND Value = @Size)
)
Begin
INSERT INTO BannerTypes (type, value, Displayorder)
	VALUES ('Size', @Size, 1)
	    
end

declare @SizeID smallint
if(@BannerType in (1,2))
begin
SELECT
	@SizeID = TypeID
FROM BannerTypes(nolock)
WHERE Type = 'Size' AND Value = @Size
  
end


BEGIN TRANSACTION

INSERT INTO Banners ([Content],
Category,
[Language],
ImageType,
[Size],
Currency,
[Type],
[LastUpdate],
CreatedDate,
UpdatedBy,
Creator,
Version)
	VALUES (@Content, @Category, @Language, @ImageType, @SizeID, @Currency, @BannerType, @CreatedDate, @CreatedDate, @UserID, @UserID, 1)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
SELECT
	@ErrCode = 501
	return
END

SELECT
	@BannerID = @@IDENTITY

--Generate filename
--Ex: @FileName = BonusEnglishImage125x125.jpg ,@BannerID=8 => @FileName=BonusEnglishImage125x125/8.jpg
--SELECT @FileName=substring(@FileName,1,len(rtrim(@FileName))-4)+'/'+convert(varchar(20),@BannerID)+'.'+right(rtrim(@filename),3)
COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000)
SELECT
	@SPName = OBJECT_NAME(@@ProcID)
SELECT
	@Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID)
	+ ' Content:' + dbo.Aff_ToString(@Content)
	+ ' Category:' + dbo.Aff_ToString(@Category)
	+ ' Language:' + dbo.Aff_ToString(@Language)
	+ ' ImageType:' + dbo.Aff_ToString(@ImageType)
	+ ' Currency:' + dbo.Aff_ToString(@Currency)
	+ ' Size:' + dbo.Aff_ToString(@Size)
	+ ' Banner Type:' + dbo.Aff_ToString(@BannerType)

EXEC [dbo].[Aff_WriteLog]	@Creator = @UserID,
							@Typename = 'Banner', -- refer to table LogType
							@SPName = @SPName,
							@Details = @Detail,
							@IP = @IP

GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_BannerIns] TO [vnteam]