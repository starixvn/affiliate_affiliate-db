ALTER PROC [dbo].[Aff_BannerIns] 
	@FileExtension VARCHAR(5)
	,@Category VARCHAR(50)
	,@Language VARCHAR(50) = 'English'
	,@ImageType VARCHAR(50)
	,@Currency VARCHAR(5)
	,@Size VARCHAR(50)
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@DeviceType TINYINT = 0 
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,@BannerID INT OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Add a new Banner
DB: DB052.Affiliate_12BET
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision] 
	- 20140708@Bobby: Apply DeviceType info

Param's Explanation:

• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @UserID
		,@funcname = '[Media]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 RETURN

	-----------------------------------------------
	DECLARE @CreatedDate DATETIME

	SELECT @CreatedDate = Current_Timestamp

	BEGIN TRANSACTION

	INSERT INTO Banners (
		FileName
		,Category
		,[Language]
		,ImageType
		,[Size]
		,Currency
		,[LastUpdate]
		,CreatedDate
		,Creator
		,DeviceType
		)
	VALUES (
		@FileExtension
		,@Category
		,@Language
		,@ImageType
		,@Size
		,@Currency
		,@CreatedDate
		,@CreatedDate
		,@UserID
		,@DeviceType
		)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrMsg = N'Error occurs.Insert unsuccessfully.'
			,@ErrCode = 1001

		RETURN
	END

	SELECT @BannerID = @@IDENTITY

	--Generate filename
	--Ex: @FileName = BonusEnglishImage125x125.jpg ,@BannerID=8 => @FileName=BonusEnglishImage125x125/8.jpg
	--SELECT @FileName=substring(@FileName,1,len(rtrim(@FileName))-4)+'/'+convert(varchar(20),@BannerID)+'.'+right(rtrim(@filename),3)
	DECLARE @FileName VARCHAR(50)

	SELECT @FileName = @Category + '/' + convert(VARCHAR(20), @BannerID) + '.' + @FileExtension

	UPDATE Banners
	SET FileName = @FileName
	WHERE BannerID = @BannerID

	COMMIT TRANSACTION

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID) + ' FileName:' + dbo.Aff_ToString(@FileName) + ' Category:' + dbo.Aff_ToString(@Category) + ' Language:' + dbo.Aff_ToString(@Language) + ' ImageType:' + dbo.Aff_ToString(@ImageType) + ' Currency:' + dbo.Aff_ToString(@Currency) + ' Size:' + dbo.Aff_ToString(@Size)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'Banner'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_BannerIns] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_BannerIns] TO [vnteam]
GO


