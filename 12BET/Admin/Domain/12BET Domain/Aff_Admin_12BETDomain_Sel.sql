/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_12BETDomain_Sel]
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - 12BET Domain - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SELECT a.DomainID, a.DomainName, b.UserName AS Creator, a.CreateDate, ISNULL(a.IsSSL, 0) AS IsSSL
	FROM [12BetDomain] a WITH (NOLOCK)
		LEFT JOIN Users b WITH (NOLOCK) ON a.Creator = b.CustId
	WHERE a.IsDeleted = 0
	ORDER BY a.DomainName
END
GO