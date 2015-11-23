ALTER PROCEDURE [dbo].[AffAdmin_CheckPermissionCurrency]
	@LicenseeID INT,
	@UserId int, 
	@CurrencyId int,
	@ErrCode int = 0 Output
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/
AS


IF (Not Exists (SELECT 1 FROM dbo.AffAdmin_f_UserCurrency_Select(@userID, @LicenseeID) WHERE AffCurrencyID = @CurrencyID))
BEGIN
	SELECT @ErrCode = 503 --You are not authorized on this Currency.
	Return
END
Select @ErrCode = 0

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CheckPermissionCurrency] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CheckPermissionCurrency] TO [vnteam] AS [dbo]