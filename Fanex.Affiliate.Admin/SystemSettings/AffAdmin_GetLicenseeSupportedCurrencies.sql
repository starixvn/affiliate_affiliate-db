/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GetLicenseeSupportedCurrencies]   
AS  
/*
Created:20161129@Joseph
Task : Get licensee currencies for integrating into LAP
DB: DBAFF - Affiliate database

Revisions:
	- 20170717@Percy: Get Original Currency [RedmineID: #80074]
	- 20180205@Percy: Remove redundant param: @LicenseeID [RedmineID: #90545]
Param's Explanation:

*/

BEGIN  
	SET NOCOUNT ON;  
 
	DECLARE @AffiliateCurrencies NVARCHAR(MAX)

	SELECT @AffiliateCurrencies=Svalue 
	FROM SystemSettings WITH (NOLOCK) 
	WHERE Sname		= 'AffiliateCurrencies' 
		AND Type	= 'Meta'  

	SELECT cc.PartnerExchangeID AS OriginalCurrencyID, c.CurrencyID, c.CurrencyCode, c.MultipliedBy  
	FROM dbo.strsplit(@AffiliateCurrencies, ',')
		INNER JOIN dbo.Currency c WITH (NOLOCK) ON c.CurrencyCode = val
		INNER JOIN dbo.CurrencyConverter cc WITH (NOLOCK) ON c.CurrencyID = cc.ExchangeID	
END
GO