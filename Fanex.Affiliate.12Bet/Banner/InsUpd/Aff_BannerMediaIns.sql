ALTER PROCEDURE [dbo].[Aff_BannerMediaIns] 
	@BannerID INT OUTPUT
	,@FileName VARCHAR(100)
	,@Category VARCHAR(50)
	,@Language VARCHAR(50) = 'English'
	,@ImageType VARCHAR(50)
	,@Currency VARCHAR(5)
	,@Size VARCHAR(50)
	,@Type TINYINT = 0
	,@AffType TINYINT = 0
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: @VinhTrinh
Task :	- Get list afftype
DB: DB052.Affiliate_12Bet
Original: [Aff_BannerMediaIns]
Param's Explanation:
	• @UserID: user deleting msg will be logged
	• @ErrCode:	
		0: Transaction recorded successfully.
		101: Invalid message ID.
		102: FileName has already been exist 
		1001: Unsuccessful deleting msg.
	• @ErrMsg: Error description.

Revisions:    
	- 20140226@Bobby: Apply AffType
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

	DECLARE @ExistFileName TINYINT

	SET @ExistFileName = (
			SELECT COUNT(b.FileName)
			FROM Banners_1 b
			WHERE b.FileName LIKE @FileName
			)

	IF @ExistFileName <> 0
	BEGIN
		SELECT @ErrMsg = N'Error occurs.FileName has already been exist.'
			,@ErrCode = 102

		RETURN
	END

	BEGIN TRANSACTION

	INSERT INTO Banners_1 (
		FileName
		,Category
		,[Language]
		,ImageType
		,[Size]
		,Currency
		,[LastUpdate]
		,CreatedDate
		,Creator
		,[Type]
		,[AffType]
		)
	VALUES (
		@FileName
		,@Category
		,@Language
		,@ImageType
		,@Size
		,@Currency
		,@CreatedDate
		,@CreatedDate
		,@UserID
		,@Type
		,@AffType
		)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrMsg = N'Error occurs.Insert unsuccessfully.'
			,@ErrCode = 1001

		RETURN
	END

	--Insert size to BannerType if the size is new
	DECLARE @ExistSize TINYINT

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

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID) + ' FileName:' + dbo.Aff_ToString(@FileName) + ' Category:' + dbo.Aff_ToString(@Category) + ' Language:' + dbo.Aff_ToString(@Language) + ' ImageType:' + dbo.Aff_ToString(@ImageType) + ' Currency:' + dbo.Aff_ToString(@Currency) + ' Size:' + dbo.Aff_ToString(@Size) + ' Type:' + dbo.Aff_ToString(@Type) + ' AffType:' + dbo.Aff_ToString(@AffType)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'Banner'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
