ALTER PROCEDURE [dbo].[Aff_TextIns_1] 
	@BannerID INT OUTPUT
	,@Message NVARCHAR(max)
	,@Category VARCHAR(50)
	,@Language VARCHAR(50) = 'English'
	,@Currency VARCHAR(5)
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@DeviceType TINYINT = 0
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Add new text Banner
DB: DB052.Affiliate_12BET
Original:

Revisions:
	- 20140708@Bobby: Apply DeviceType info

Param's Explanation:
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

	INSERT INTO Banners_1 (
		[Message]
		,Category
		,[Language]
		,ImageType
		,Currency
		,[LastUpdate]
		,CreatedDate
		,Creator
		,[FileName]
		,[DeviceType]
		)
	VALUES (
		@Message
		,@Category
		,@Language
		,'Text'
		,@Currency
		,@CreatedDate
		,@CreatedDate
		,@UserID
		,''
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

	COMMIT TRANSACTION

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID) + ' Category:' + dbo.Aff_ToString(@Category) + ' Language:' + dbo.Aff_ToString(@Language) + ' ImageType:Text' + ' Currency:' + dbo.Aff_ToString(@Currency)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'Banner'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_TextIns_1] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TextIns_1] TO [VNTeam]
