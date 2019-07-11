/*<info serverAlias="DBAFF-Affiliate_Athena000" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[AffAdmin_f_UserCurrency_Select]
(
	@UserID		INT,
	@LicenseeID INT
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
	Created: 20151117@Victor
	Task: SSO from Internal Admin to Affiliate Admin
	DB: DBAFF.Affiliate_XXX

	Revisions:
		- 20190424@Percy: Migrate DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	DECLARE @sql VARCHAR(1000)	
	DECLARE @GroupID INT
	DECLARE @IsITAdmin BIT = 0

	DECLARE @AffiliateCurrencies NVARCHAR(MAX)
	SELECT  @AffiliateCurrencies = Svalue FROM dbo.SystemSettings WITH (NOLOCK) WHERE Sname = 'AffiliateCurrencies'

	SELECT @GroupID = GroupID FROM DBCUST.bodb_licensee.dbo.Aff_LicenseeUser lu WITH (NOLOCK) WHERE lu.IsActive = 1 AND lu.UserID = @UserID AND lu.LicenseeID = @LicenseeID
	SELECT @IsITAdmin = CASE WHEN GroupName LIKE 'Aff_IT_Dept' THEN 1 ELSE 0 END FROM DBCUST.bodb_licensee.dbo.Aff_GroupInfo WITH (NOLOCK) WHERE GroupID = @GroupID

	IF @IsITAdmin = 0
	BEGIN
		DECLARE @System INT
		SELECT  @System = id FROM DBCUST.bodb_licensee.dbo.Systems WITH (NOLOCK) WHERE SystemName LIKE 'AFF'

		INSERT INTO @tbData (UserID, LicenseeID, CurrencyID, AffCurrencyID)
		SELECT UsrID, cu.LicenseeID, CurrencyID, NULL 
		FROM DBCUST.bodb_licensee.dbo.CurrencyUser cu WITH (NOLOCK) 
		WHERE SystemID = @System -- Affliate 
			AND cu.IsActive = 1
			AND cu.UsrID = @UserID
			AND cu.LicenseeID = @LicenseeID

		UPDATE @tbData
		SET AffCurrencyID = c.ExchangeID
		FROM @tbData d
			INNER JOIN dbo.CurrencyConverter c ON c.PartnerExchangeID = d.CurrencyID

		DELETE FROM @tbData WHERE AffCurrencyID IS NULL
	END
	ELSE -- IT Admin account
	BEGIN
		INSERT INTO @tbData (UserID, LicenseeID, CurrencyID, AffCurrencyID)
		SELECT @UserID, @LicenseeID, cc.PartnerExchangeID, c.CurrencyID
		FROM dbo.strsplit(@AffiliateCurrencies, ',')
			INNER JOIN dbo.Currency c WITH (NOLOCK) ON c.CurrencyCode = val
			LEFT JOIN dbo.CurrencyConverter cc WITH (NOLOCK) ON c.CurrencyID = cc.ExchangeID
	END
	RETURN
END
GO