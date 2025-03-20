/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_LicenseeDomain_Sel]
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - 12BET Domain - Select

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250311@Lewis: Add block market [RedmineID: #219496]
*/

BEGIN
	SET NOCOUNT ON

	SELECT 
			a.DomainID
			, a.DomainName
			, b.Username AS Creator
			, a.CreateDate, ISNULL(a.IsSSL, 0) AS IsSSL
			, a.BlockMarket
	FROM LicenseeDomain a WITH (NOLOCK)
		INNER JOIN Affiliate_User b WITH (NOLOCK) ON a.Creator = b.CustId
	WHERE IsDeleted = 0
	ORDER BY a.DomainName
END
GO