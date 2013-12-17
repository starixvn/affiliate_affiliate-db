-- =============================================
-- Script Template
-- =============================================
use Affiliate_12BET
go
ALTER PROCEDURE [dbo].[Aff_BannerMediaIns]
	@BannerID int OUTPUT,
	@FileName varchar(100), 
	@Category varchar(50),
	@Language varchar(50)='English',
	@ImageType varchar(50),
	@Currency varchar(5),
	@Size varchar(50),
	@Type tinyint = 0,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Param's Explanation:

• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
102: FileName has already been exist 
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
declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp
declare @ExistFileName tinyint
SET @ExistFileName=(SELECT	COUNT(b.FileName)
					FROM	Banners_1 b
					WHERE	b.FileName like @FileName)
IF @ExistFileName<>0
BEGIN
	Select @ErrMsg = 	N'Error occurs.FileName has already been exist.', @ErrCode = 102
	return
END

BEGIN TRANSACTION
INSERT INTO Banners_1
	(	
		FileName, 
		Category,
		[Language],
		ImageType,
		[Size],
		Currency,
		[LastUpdate],
		CreatedDate,
		Creator,
		[Type]
	)
	VALUES
	(	
		@FileName,		
		@Category,
		@Language,
		@ImageType,
		@Size,
		@Currency,
		@CreatedDate,
		@CreatedDate,
		@UserID,
		@Type
	)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = 	N'Error occurs.Insert unsuccessfully.', @ErrCode = 1001
	return
END

--Insert size to BannerType if the size is new
declare @ExistSize tinyint
SET @ExistSize=	(SELECT	COUNT(b.Value)
				FROM	BannerTypes_1 b
				WHERE	b.Value like @Size)
IF @ExistSize=0
BEGIN
	EXEC [dbo].[Aff_BannerInsType_1] 
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

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID) 
					+ ' FileName:' + dbo.Aff_ToString(@FileName)
					+ ' Category:' + dbo.Aff_ToString(@Category)
					+ ' Language:' + dbo.Aff_ToString(@Language)
					+ ' ImageType:' + dbo.Aff_ToString(@ImageType)
					+ ' Currency:' + dbo.Aff_ToString(@Currency)
					+ ' Size:' + dbo.Aff_ToString(@Size)          
					+ ' Size:' + dbo.Aff_ToString(@Type)          

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP



