ALTER PROCEDURE [dbo].[AffAdmin_UserCurrency_Delete]
(
	@UserID	INT,
	@LicenseeID INT
)
/*
	Created: 20151111@Victor
	DB: DBLIC/bodb_licensee
	Remark: Delete User's Currency data
	Revision:
*/
AS
BEGIN
	DECLARE @System INT
	SELECT @System = id FROM dbo.Systems WITH (NOLOCK) WHERE SystemName LIKE 'AFF'

	DELETE FROM dbo.CurrencyUser 
	WHERE SystemID = @System -- Affiliate
		AND UsrID = @UserID
		AND LicenseeID = @LicenseeID
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_UserCurrency_Delete] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UserCurrency_Delete] TO [vnteam]