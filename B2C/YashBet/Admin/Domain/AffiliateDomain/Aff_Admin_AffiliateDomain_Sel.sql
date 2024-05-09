/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Sel]
AS

/*  
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Domain - Affiliate Domain - Select

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT a.DomainID, a.DomainName, b.Username AS Creator, a.CreateDate, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.Affiliate_User b WITH (NOLOCK) ON a.Creator = b.CustId
	WHERE IsDeleted = 0
	ORDER BY a.DomainName
END
GO