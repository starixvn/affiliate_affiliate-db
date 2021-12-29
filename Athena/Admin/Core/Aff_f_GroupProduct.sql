/*<info serverAlias="DBAFF-Affiliate_Athena000" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GroupProduct] ()
RETURNS TABLE
AS

/*
	Created: 20211222@Percy
	DB: DBAFF-Affiliate_Athena000
	Task: Group Product

	Revisions:
		- 20211222@Percy: Initiliaze function [RedmineID: #165777]
*/

RETURN
	SELECT
		CONVERT(INT, 1)						AS ProductId
		,CONVERT(VARCHAR(50), 'Sportsbook')	AS ProductName
		,CONVERT(INT, 1)					AS GroupProductId
		,CONVERT(VARCHAR(50), 'Sportsbook')	AS GroupProductName
		,CONVERT(INT, 1)					AS API_ProductId
		,CONVERT(INT, 1)					AS GroupAPI_ProductId
	UNION ALL
	SELECT ProductId, ProductName, 1 AS GroupProductId, 'Sportsbook' AS GroupProductName, API_ProductId, 1 AS GroupAPI_ProductId
	FROM dbo.Product WITH (NOLOCK) WHERE API_ProductId = 63 -- SLT
GO