ALTER PROCEDURE [dbo].[Aff_TextSelDetail_1] 
	@TextID INT
AS
BEGIN
	SET NOCOUNT ON

	SELECT TOP (1) BannerID
		,Category
		,[Language]
		,Lastupdate
		,Currency
		,[Message]
		,[dbo].[Aff_GetDeviceType](DeviceType) DeviceType
	FROM Banners_1 WITH (NOLOCK)
	WHERE BannerID = @TextID
END
GO

GRANT EXECUTE ON [dbo].[Aff_TextSelDetail_1] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_TextSelDetail_1] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_TextSelDetail_1] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TextSelDetail_1] TO [VNTeam]
