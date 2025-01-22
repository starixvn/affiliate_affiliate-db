/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_SubAffiliateDomain_Sel]
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Sub Affiliate Domain - Select

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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