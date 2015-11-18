ALTER FUNCTION [dbo].AffAdmin_f_UserCurrency_Select
(		
	@UserID INT,
	@LicenseeID INT,
	@AffCurrencyID INT
)
RETURNS @tbData TABLE
(
	UserID			INT,
	LicenseeID		INT,
	CurrencyID		INT,
	AffCurrencyID	INT
) 
AS	
/*
Created:20151117@Victor
Task :  SSO from Internal Admin to Affiliate Admin
DB: DBAFF - Affiliate database

Revisions:
Param's Explanation:

*/

BEGIN
	SET @UserID = ISNULL(@UserID,'')
	SET @LicenseeID = ISNULL(@LicenseeID,'')
	SET @AffCurrencyID = ISNULL(@AffCurrencyID,'')

	INSERT INTO @tbData (UserID, LicenseeID, CurrencyID, AffCurrencyID)
	SELECT UsrID, LicenseeID, CurrencyID, NULL
	FROM DBLIC.bodb_licensee.dbo.CurrencyUser cu WITH (NOLOCK) 
	WHERE SystemID = 7 -- Affliate
		AND IsActive = 1
		AND (@UserID = '' OR UsrID = @UserID)
		AND (@LicenseeID = '' OR LicenseeID = @LicenseeID)
	
	UPDATE @tbData
	SET AffCurrencyID = c.ExchangeID
	FROM @tbData d
		INNER JOIN dbo.CurrencyConverter c ON c.PartnerExchangeID = d.CurrencyID

	IF (@AffCurrencyID != '')
		DELETE FROM @tbData WHERE AffCurrencyID != @AffCurrencyID

	RETURN
END

GO
GRANT SELECT ON [dbo].AffAdmin_f_UserCurrency_Select TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].AffAdmin_f_UserCurrency_Select TO [vnteam]


