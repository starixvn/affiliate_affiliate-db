ALTER PROCEDURE [dbo].[Aff_BannerIns]
	@BannerID int OUTPUT,
	@FileExtension varchar(100), 
	@Category varchar(50),
	@Language varchar(50)='English',
	@ImageType varchar(50),
	@Currency varchar(5),
	@Size varchar(50),
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Add a new Banner
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
declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp

BEGIN TRANSACTION
INSERT INTO Banners
	(	
		FileName, 
		Category,
		[Language],
		ImageType,
		[Size],
		Currency,
		[LastUpdate],
		CreatedDate,
		Creator
	)
	VALUES
	(	
		@FileExtension,		
		@Category,
		@Language,
		@ImageType,
		@Size,
		@Currency,
		@CreatedDate,
		@CreatedDate,
		@UserID
	)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = 	N'Error occurs.Insert unsuccessfully.', @ErrCode = 1001
	return
END

SELECT @BannerID = @@IDENTITY

--Generate filename
--Ex: @FileName = BonusEnglishImage125x125.jpg ,@BannerID=8 => @FileName=BonusEnglishImage125x125/8.jpg
--SELECT @FileName=substring(@FileName,1,len(rtrim(@FileName))-4)+'/'+convert(varchar(20),@BannerID)+'.'+right(rtrim(@filename),3)
declare @FileName varchar(50)
SELECT @FileName=@Category + '/' + convert(varchar(20),@BannerID)+'.' + @FileExtension

UPDATE Banners SET FileName=@FileName WHERE BannerID=@BannerID
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

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP


GO
GRANT EXECUTE ON [dbo].[Aff_BannerIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerIns] TO [vnteam]
GO