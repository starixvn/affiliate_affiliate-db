ALTER PROCEDURE [dbo].[Aff_BannerUpd]
	@BannerID int ,
	@FileName varchar(100)=null,
	@Category varchar(50)=null,
	@Language varchar(50)=null,
	@ImageType varchar(50)=null,
	@Size varchar(50)=null,
	@Currency varchar(5)=null,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task :Update affiliate Banners
DB: DB052.Affiliate_12BET
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
EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@UserID,@funcname='[Media]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------

BEGIN TRANSACTION

--Get the old size of the banner
Declare @OldSize varchar(50)
SET @OldSize =	(SELECT	b.Size
				FROM	Banners b
				WHERE	b.BannerID = @BannerID)

UPDATE Banners with(rowlock,updlock)
SET 	
	LastUpdate = getdate(),
	UpdatedBy=@UserID,
	FileName=coalesce(@FileName,FileName),
	Category=coalesce(@Category,Category),
	Language=coalesce(@Language,Language),
	ImageType=coalesce(@ImageType,ImageType),
	Size=coalesce(@Size,@Size),
	Currency=coalesce(@Currency,Currency)
WHERE BannerID=@BannerID
IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = N'Error occurs.Update unsuccessfully.', @Errcode=1001
	return
END 

--Delete the old size if there is no banner uses it
Declare @ExistSize tinyint
SET @ExistSize=	(SELECT	COUNT(b.Size)
				FROM	Banners b
				WHERE	b.Size like @OldSize)
IF @ExistSize=0
BEGIN
	EXEC [dbo].[Aff_BannerDelType] 
	@TypeName='Size',
	@Value=@OldSize,
	@UserID = @UserID,
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output

	If @ErrCode <> 0
	BEGIN
		ROLLBACK TRANSACTION
		return
	END
END

--Add new size to BannerTypes table if it is new
SET @ExistSize=	(SELECT	COUNT(b.Value)
				FROM	BannerTypes b
				WHERE	b.Value like @Size)
IF @ExistSize=0
BEGIN
	EXEC [dbo].[Aff_BannerInsType] 
	@TypeName='Size',
	@Value=@Size,
	@UserID = @UserID,
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output

	If @ErrCode <> 0
	BEGIN
		ROLLBACK TRANSACTION
		return
	END
END

COMMIT TRANSACTION

Select @Errcode=0

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) 
				  +  ' FileName:' + dbo.Aff_ToString(@FileName)
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
GRANT EXECUTE ON [dbo].[Aff_BannerUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerUpd] TO [VNTeam]
