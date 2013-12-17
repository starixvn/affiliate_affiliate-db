ALTER Procedure [dbo].[AffAdmin_DomainAffSel]  
   
AS  
 Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate  
 From AffDomain a with(nolock)  
  inner join AdminUser b with (nolock) on a.Creator = b.CustId  
 order by a.DomainName  
  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffSel] TO [vnteam]