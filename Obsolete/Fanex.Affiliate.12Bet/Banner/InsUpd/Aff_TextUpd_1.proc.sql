ALTER PROCEDURE [dbo].[Aff_TextUpd_1] 
	@BannerID INT
	,@Message NVARCHAR(max)
	,@Category VARCHAR(50) = NULL
	,@Language VARCHAR(50) = NULL
	,@Currency VARCHAR(5) = NULL
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@DeviceType TINYINT = 0
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Update a text Banner
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
	UPDATE Banners_1 WITH (ROWLOCK, UPDLOCK)
	SET LastUpdate = getdate()
		,UpdatedBy = @UserID
		,[Message] = coalesce(@Message, Category)
		,Category = coalesce(@Category, Category)
		,[Language] = coalesce(@Language, [Language])
		,Currency = coalesce(@Currency, Currency)
		,DeviceType = @DeviceType
	WHERE BannerID = @BannerID

	IF @@Error <> 0
	BEGIN
		SELECT @ErrMsg = N'Error occurs.Updte unsuccessfully.'
			,@Errcode = 1001

		RETURN
	END

	SELECT @Errcode = 0

	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) + ' Message:' + @Message + ' Category:' + dbo.Aff_ToString(@Category) + ' Language:' + dbo.Aff_ToString(@Language) + ' Currency:' + dbo.Aff_ToString(@Currency)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'Banner'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_TextUpd_1] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TextUpd_1] TO [VNTeam]
