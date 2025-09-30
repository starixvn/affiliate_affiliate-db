ALTER FUNCTION [dbo].[AffAdmin_PermissionOnAffiliate]
(
	@LicenseeID INT,
	@UserId int, 
	@AffId int
)
RETURNS Bit
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/
AS
BEGIN
	Declare @result bit
	Select @result = 0
	If Exists ( SELECT 1	
				FROM dbo.AffAdmin_f_UserCurrency_Select(@userID, @LicenseeID) r
					INNER JOIN AffInfo a with (nolock) on r.AffCurrencyID = a.Currency
				WHERE a.AffId = @AffId
			)
	BEGIN
		Select @result = 1
	END

	Return @result
END