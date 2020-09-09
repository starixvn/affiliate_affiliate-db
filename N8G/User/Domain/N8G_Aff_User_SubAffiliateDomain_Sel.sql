/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_SubAffiliateDomain_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User - Domain - Sub Affiliate Domain

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SELECT DomainId, DomainName, IsSSL
	FROM dbo.SubAffDomain WITH (NOLOCK)
	WHERE IsDeleted = 0
	ORDER BY DomainName
END
GO