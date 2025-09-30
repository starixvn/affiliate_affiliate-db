CREATE PROCEDURE [dbo].[AffAdmin_SystemSettingsExchange]
AS

SET NOCOUNT ON

SELECT ExchangeID, Code, Prefix
from Exchange nolock
WHERE Code IN 
		(SELECT SValue 
		FROM SystemSettings nolock
		where SName = 'SystemCurrency' AND Type = 'Meta')

GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsExchange] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_SystemSettingsExchange] TO [vnteam]