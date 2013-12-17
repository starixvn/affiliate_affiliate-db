CREATE Procedure [dbo].[AffAdmin_DomainMemSelById]  
   @DomainId int
AS  

Select a.DomainID, a.DomainName
From [MemberDomain] a with(nolock)  
	inner join AdminUser b with (nolock) on a.Creator = b.CustId  
where DomainId = @DomainId
order by a.DomainName  
  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSelById] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemSelById] TO [vnteam]