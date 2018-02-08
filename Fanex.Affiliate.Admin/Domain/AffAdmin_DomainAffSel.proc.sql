/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_DomainAffSel]  
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180208@Alex  : Support Liecnsee admin portal #90545
*/
AS  
 Select a.DomainID, a.DomainName, a.CreatorName as Creator, a.CreateDate  
 From AffDomain a with(nolock)  
 order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffSel] TO [vnteam] AS [dbo]