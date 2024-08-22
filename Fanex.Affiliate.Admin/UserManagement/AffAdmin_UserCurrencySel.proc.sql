/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_UserCurrencySel]
	@LicenseeID INT,	
	@UserID		INT
AS

/*
	Created:20130729@Jim
	Task: Restrict permission of Aff Users by currency
	DB: DBAFF-Affiliate_Athena000

	Revisions:
		- 20130823@Jim: add more column currencyCode in result 
		- 20131223@Bobby: check constraint's groupid to AdminUser
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function AffAdmin_f_AdminUserInfo_Select [RedmineID: #103658]
		- 20240807@Sally: Remove linked server to DBCust [RedmineID: #206891]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @Users TABLE (UserID INT)
	INSERT INTO @Users (UserID)
	SELECT UserID 
	FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(@UserID, @LicenseeID)

	DECLARE @Currency VARCHAR(MAX)
	SELECT  @Currency = Svalue 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE Sname = 'AffiliateCurrencies'
	
	;WITH cte_Currency AS (
		SELECT CONVERT(VARCHAR(10), s.value) AS CurrencyCode 
		FROM STRING_SPLIT(@Currency, ',')s
	)
	SELECT	DISTINCT c.CurrencyID,
			CASE	WHEN c.CurrencyID = 20 THEN 'UUS'
					WHEN c.CurrencyID = 51 THEN 'INH'
					ELSE c.CurrencyCode END AS CurrencyName,
			CASE	WHEN c.CurrencyID = 20 THEN 'UUS'
					WHEN c.CurrencyID = 51 THEN 'INH'
					ELSE c.CurrencyCode END AS CurrencyCode, --- add more for support web dev to re-map Currency Name
			CASE	WHEN ISNULL(ctmp.affcurrencyID, 0) = 0 THEN 0
					ELSE 1 END AS isActive
	FROM cte_currency cy 
		INNER JOIN dbo.Currency c WITH (NOLOCK) ON cy.CurrencyCode = c.CurrencyCode 
		LEFT JOIN (
			SELECT au.UserID, ag.affcurrencyID 
			FROM @Users au
				INNER JOIN dbo.AffAdmin_f_UserCurrency_Select(@UserID, @LicenseeID) ag ON au.userid = ag.userid
		) AS ctmp ON c.CurrencyID = ctmp.affcurrencyID
	ORDER BY CASE 	WHEN c.CurrencyID = 20 THEN 'UUS'
					WHEN c.CurrencyID = 51 THEN 'INH'
					ELSE c.CurrencyCode END
END
GO