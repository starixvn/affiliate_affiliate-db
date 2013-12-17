CREATE FUNCTION [dbo].[AffAdmin_PermissionOnAffiliate]
(
	@UserId int, 
	@AffId int
)
RETURNS Bit
AS
BEGIN
	Declare @result bit
	Select @result = 0
	If Exists ( SELECT 1	
				FROM dbo.Aff_f_GetCurrencybyUser (@userID, 1) r
					INNER JOIN AffInfo a with (nolock) on r.AttributeID = a.Currency
				WHERE a.AffId = @AffId
			)
	BEGIN
		Select @result = 1
	END

	Return @result
END