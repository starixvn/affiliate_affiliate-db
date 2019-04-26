/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_SystemSupportedCurrencies] 
	@LicenseeID INT,
	@UserId		INT
AS

/*    
	Task: Get Affiliate System Supported Currencies Information  
	DB: DBAFF-Affiliate_Athena000
	Original:[Aff_SystemSupportedCurrencies]      
	
	Revisions:          
		- 20130219@Peter: created 
		- 20130830@Joseph: restrict user permission by currency   
		- 20140112@Bobby.Nguyen: replace AFF_AffiliateCurrencies to AffiliateCurrencies key
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_UserCurrency_Select
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @tblCurrency TABLE (CurrencyID INT)

	SELECT @sql = 'SELECT CurrencyID FROM OPENQUERY(DBCUST,
								''SELECT CurrencyID FROM bodb_Licensee.dbo.AffAdmin_f_UserCurrency_Select(' + CONVERT(VARCHAR(10), @UserId) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @tblCurrency (CurrencyID)
	EXEC (@sql)

	DECLARE @Currencies VARCHAR(MAX)
	SELECT  @Currencies = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffiliateCurrencies' AND Type = 'Meta'

	-- Insert statements for procedure here  
	SELECT c.CurrencyID
		,c.CurrencyCode
		,c.MultipliedBy
	FROM dbo.Currency WITH (NOLOCK) c
		INNER JOIN @tblCurrency tmp ON c.CurrencyID = tmp.CurrencyID
	WHERE c.CurrencyCode IN (SELECT val FROM [dbo].[strSplit](@Currencies, ',') )
END
GO