ALTER PROCEDURE [dbo].[AffAdmin_UserCurrency_Insert]
(
	@UserID			INT,
	@LicenseeID		INT,
	@currencyIDs	VARCHAR(1000),
	@IsActive		INT = 1
)
/*
	Created: 20151118@Victor
	DB: DBLIC/bodb_licensee
	Remark: Insert User's Currency
	Revision:
*/
AS
BEGIN
	DECLARE @System INT
	SELECT @System = id FROM dbo.Systems WITH (NOLOCK) WHERE SystemName LIKE 'AFF'

	DECLARE @CurrencyList TABLE (CurrencyID INT)
	INSERT INTO @CurrencyList (CurrencyID)
	SELECT CAST(val AS INT) FROM bodb02.dbo.Lrf_f_StringSplit(@currencyIDs, ',')
	
	INSERT INTO dbo.CurrencyUser (usrID, LicenseeID, CurrencyID, SystemID, isActive)
	SELECT @UserID, @LicenseeID, CurrencyID, @System, @IsActive -- Affiliate
	FROM @CurrencyList

END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserCurrency_Insert] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UserCurrency_Insert] TO [vnteam] AS [dbo]