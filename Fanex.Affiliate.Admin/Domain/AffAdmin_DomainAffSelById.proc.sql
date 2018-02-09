/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_DomainAffSelById] 
   @DomainId int
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180208@Alex  : Support Liecnsee admin portal #90545
*/
AS  

Select a.DomainID, a.DomainName
From AffDomain a with(nolock)  
where DomainId = @DomainId
order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffSelById] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffSelById] TO [vnteam] AS [dbo]