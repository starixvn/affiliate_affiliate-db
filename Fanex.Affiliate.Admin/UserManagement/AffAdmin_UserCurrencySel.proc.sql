ALTER  PROCEDURE  [dbo].[AffAdmin_UserCurrencySel]		
	@UserID INT
AS	
/*
Created:20130729@Jim
Task :  Restrict permission of Aff Users by currency
DB: DBLIC.Affiliate_Alpha

Revisions:
    -20130823@Jim: add more column currencyCode in result 
	-20131223@Bobby: check constraint's groupid to AdminUser
Param's Explanation:

*/
/*
[Aff_UserCurrencySel] @UserID=1
*/

SET NOCOUNT ON

BEGIN
	DECLARE @Currency varchar(max)
	select @Currency=Svalue FROM SystemSettings WITH (NOLOCK) WHERE Sname='AffiliateCurrencies'
	
	;WITH cte_Currency 
	AS
	(
	select val from dbo.strsplit(@Currency, ',')
	)
	SELECT DISTINCT c.CurrencyID,
		   CASE WHEN c.CurrencyID =20 THEN 'UUS'
				WHEN c.CurrencyID =51 THEN 'INH'
				ELSE c.CurrencyCode 
				END AS CurrencyName,
			CASE WHEN c.CurrencyID =20 THEN 'UUS'
				WHEN c.CurrencyID =51 THEN 'INH'
				ELSE c.CurrencyCode 
				END AS CurrencyCode, --- add more for support web dev to re-map Currency Name
			CASE WHEN ISNULL(ctmp.AttributeID,0)=0 
				 THEN 0 ELSE 1 
				 END isActive		
	FROM cte_currency cy 
		INNER JOIN dbo.Currency c WITH (NOLOCK) ON cy.val=c.CurrencyCode 
		left JOIN (select au.CustID, ag.AttributeID from [dbo].[AdminUser] au with (nolock)
				join dbo.AffGroupPermissionDetail ag with (nolock) on au.custid=ag.objectid and au.groupid=ag.groupid
		where ag.objectid = @UserID AND ag.TypeID=1) ctmp ON c.CurrencyID=ctmp.AttributeID
		--LEFT JOIN dbo.AffGroupPermissionDetail ad WITH (NOLOCK) ON c.CurrencyID=ad.AttributeID AND ad.ObjectID=@UserID AND ad.TypeID=1 ---- Currency permission
	ORDER BY CASE 	WHEN c.CurrencyID =20 THEN 'UUS'
					WHEN c.CurrencyID =51 THEN 'INH'
					ELSE c.CurrencyCode 
			 END 
		
END


