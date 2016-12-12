ALTER PROCEDURE [dbo].[AffAdmin_GetLicenseeSupportedCurrencies]   
 @LicenseeID INT
AS  
/*
Created:20161129@Joseph
Task : Get licensee currencies for integrating into LAP
DB: DBAFF - Affiliate database

Revisions:
Param's Explanation:

*/

BEGIN  
	SET NOCOUNT ON;  
 
	DECLARE @AffiliateCurrencies NVARCHAR(MAX)

	SELECT @AffiliateCurrencies=Svalue 
	FROM SystemSettings WITH (NOLOCK) 
	WHERE Sname		= 'AffiliateCurrencies' 
		AND Type	= 'Meta'  

	SELECT c.CurrencyID,c.CurrencyCode,c.MultipliedBy  
	FROM dbo.strsplit(@AffiliateCurrencies, ',')
		INNER JOIN dbo.Currency c WITH (NOLOCK) 
		ON c.CurrencyCode = val
	
END
GRANT EXECUTE ON [dbo].[AffAdmin_GetLicenseeSupportedCurrencies] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GetLicenseeSupportedCurrencies] TO [vnteam] AS [dbo]