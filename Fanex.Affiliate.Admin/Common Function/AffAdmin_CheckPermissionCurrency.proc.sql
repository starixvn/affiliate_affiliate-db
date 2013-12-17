ALTER PROCEDURE [dbo].[AffAdmin_CheckPermissionCurrency]
	@UserId int, 
	@CurrencyId int,
	@ErrCode int = 0 Output
AS


IF (Not Exists (SELECT 1 FROM dbo.Aff_f_GetCurrencybyUser (@userID, 1) WHERE AttributeID = @CurrencyId))
BEGIN
	SELECT @ErrCode = 503 --You are not authorized on this Currency.
	Return
END
Select @ErrCode = 0

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CheckPermissionCurrency] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CheckPermissionCurrency] TO [vnteam] AS [dbo]