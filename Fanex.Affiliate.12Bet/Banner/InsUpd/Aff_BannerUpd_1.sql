ALTER PROCEDURE [dbo].[Aff_BannerUpd_1] 
	@BannerID INT
	,@FileName VARCHAR(100) = NULL
	,@Category VARCHAR(50) = NULL
	,@Language VARCHAR(50) = NULL
	,@ImageType VARCHAR(50) = NULL
	,@Size VARCHAR(50) = NULL
	,@Currency VARCHAR(5) = NULL
	,@UserID INT
	,@AffType TINYINT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task :Update affiliate Banners
DB: DB052.Affiliate_12BET
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision] 
	- 20140226@Bobby: Apply AffType	

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
	BEGIN TRANSACTION

	--Get the old size of the banner
	DECLARE @OldSize VARCHAR(50)

	SET @OldSize = (
			SELECT b.Size
			FROM Banners_1 b
			WHERE b.BannerID = @BannerID
			)

	UPDATE Banners_1 WITH (ROWLOCK, UPDLOCK)
	SET LastUpdate = getdate()
		,UpdatedBy = @UserID
		,FileName = coalesce(@FileName, FileName)
		,Category = coalesce(@Category, Category)
		,LANGUAGE = coalesce(@Language, LANGUAGE)
		,ImageType = coalesce(@ImageType, ImageType)
		,Size = coalesce(@Size, @Size)
		,Currency = coalesce(@Currency, Currency)
		,AffType = @AffType
	WHERE BannerID = @BannerID

	IF @@Error <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrMsg = N'Error occurs.Update unsuccessfully.'
			,@Errcode = 1001

		RETURN
	END

	--Delete the old size if there is no banner uses it
	DECLARE @ExistSize TINYINT

	SET @ExistSize = (
			SELECT COUNT(b.Size)
			FROM Banners_1 b
			WHERE b.Size LIKE @OldSize
			)

	IF @ExistSize = 0
	BEGIN
		EXEC [dbo].[Aff_BannerDelType_1] @TypeName = 'Size'
			,@Value = @OldSize
			,@UserID = @UserID
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			ROLLBACK TRANSACTION

			RETURN
		END
	END

	--Add new size to BannerTypes table if it is new
	SET @ExistSize = (
			SELECT COUNT(b.Value)
			FROM BannerTypes_1 b
			WHERE b.Value LIKE @Size
			)

	IF @ExistSize = 0
	BEGIN
		EXEC [dbo].[Aff_BannerInsType_1] @TypeName = 'Size'
			,@Value = @Size
			,@UserID = @UserID
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			ROLLBACK TRANSACTION

			RETURN
		END
	END

	COMMIT TRANSACTION

	SELECT @Errcode = 0

	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) + ' FileName:' + dbo.Aff_ToString(@FileName) + ' Category:' + dbo.Aff_ToString(@Category) + ' Language:' + dbo.Aff_ToString(@Language) + ' ImageType:' + dbo.Aff_ToString(@ImageType) + ' Size:' + dbo.Aff_ToString(@Size) + ' Currency:' + dbo.Aff_ToString(@Currency) + ' AffType:' + dbo.Aff_ToString(@AffType)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'Banner'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_BannerUpd_1] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_BannerUpd_1] TO [VNTeam]
