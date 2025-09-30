/*<info serverAlias="DBAFF-Affiliate_Athena000" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
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
	DB: DBAFF-Affiliate_Athena000

	Revisions:
		- 20190424@Percy: Migrate DBCUST.bodb_Licensee [RedmineID: #103658]
		- 20240806@Sally: Remove linked server to DBCust [RedmineID: #206891]

*/

BEGIN
	DECLARE @GroupID INT
	DECLARE @IsITAdmin BIT = 0

	DECLARE @AffiliateCurrencies NVARCHAR(MAX)
		,@AffiliateCurrenciesType TINYINT = 1

	SELECT  @AffiliateCurrencies = Svalue 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE Sname = 'AffiliateCurrencies'

	SELECT @GroupID = GroupID 
	FROM bodb_licensee.dbo.Aff_LicenseeUser lu WITH (NOLOCK) 
	WHERE lu.IsActive = 1 
		AND lu.UserID = @UserID 
		AND lu.LicenseeID = @LicenseeID

	SELECT @IsITAdmin = CASE WHEN GroupName LIKE 'Aff_IT_Dept' THEN 1 ELSE 0 END 
	FROM bodb_licensee.dbo.Aff_GroupInfo WITH (NOLOCK) 
	WHERE GroupID = @GroupID

	IF @IsITAdmin = 0
	BEGIN
		DECLARE @System INT
		SELECT  @System = id 
		FROM bodb_licensee.dbo.Systems WITH (NOLOCK) 
		WHERE SystemName LIKE 'AFF'

		INSERT INTO @tbData (UserID, LicenseeID, CurrencyID, AffCurrencyID)
		SELECT UsrID, cu.LicenseeID, CurrencyID, NULL 
		FROM bodb_licensee.dbo.CurrencyUser cu WITH (NOLOCK) 
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
		SELECT @UserID, @LicenseeID, t.PartnerExchangeID, t.CurrencyID
		FROM dbo.Aff_f_Get_PartnerExchangeID(@AffiliateCurrencies, @AffiliateCurrenciesType) t
	END
	RETURN
END
GO