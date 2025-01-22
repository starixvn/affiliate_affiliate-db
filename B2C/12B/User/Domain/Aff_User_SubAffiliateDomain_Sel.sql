/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_SubAffiliateDomain_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User - Domain - Sub Affiliate Domain

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	SELECT DomainId, DomainName, IsSSL
	FROM dbo.SubAffDomain WITH (NOLOCK)
	WHERE IsDeleted = 0
	ORDER BY DomainName
END
GO