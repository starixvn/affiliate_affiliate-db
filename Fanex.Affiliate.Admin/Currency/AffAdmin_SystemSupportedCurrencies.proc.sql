ALTER PROCEDURE [dbo].[AffAdmin_SystemSupportedCurrencies] @UserId INT
AS
/*    
Task : Get Affiliate System Supported Currencies Information  
DB:    
Original:[Aff_SystemSupportedCurrencies]      
Revisions:          
 - 20130219@Peter: created 
 - 20130830@Joseph: restrict user permission by currency   
 - 20140112@Bobby.Nguyen: replace AFF_AffiliateCurrencies to AffiliateCurrencies key
 */
BEGIN
	SET NOCOUNT ON;

	SELECT AttributeID AS CurrencyID
	INTO #tmpCurrency
	FROM dbo.Aff_f_GetCurrencybyUser(@UserId, 1)

	DECLARE @Currencies VARCHAR(max)

	SELECT @Currencies = (
			SELECT SValue
			FROM SystemSettings
			WHERE SName = 'AffiliateCurrencies'
				AND Type = 'Meta'
			)

	-- Insert statements for procedure here  
	SELECT c.CurrencyID
		,c.CurrencyCode
		,c.MultipliedBy
	FROM Currency(NOLOCK) c
		INNER JOIN #tmpCurrency tmp ON c.CurrencyID = tmp.CurrencyID
	WHERE c.CurrencyCode IN (
			SELECT val
			FROM [dbo].[strSplit](@Currencies, ',')
			)
END 
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSupportedCurrencies] TO [bodbAdminNet]
