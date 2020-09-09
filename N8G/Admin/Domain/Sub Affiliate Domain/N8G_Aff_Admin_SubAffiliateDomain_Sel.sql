/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_SubAffiliateDomain_Sel]
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin - Domain - Sub Affiliate Domain - Select

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SELECT a.DomainId, a.DomainName, b.Username AS Creator, a.CreateDate, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.SubAffDomain a WITH (NOLOCK)
		LEFT JOIN dbo.Affiliate_User b WITH (NOLOCK) ON a.Creator = b.CustId
	WHERE a.IsDeleted = 0
	ORDER BY a.DomainName
END
GO