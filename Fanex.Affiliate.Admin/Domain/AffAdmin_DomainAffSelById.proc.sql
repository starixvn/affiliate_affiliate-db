ALTER PROCEDURE [dbo].[AffAdmin_DomainAffSelById] 
	@LicenseeID int, 
   @DomainId int
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/
AS  

Select a.DomainID, a.DomainName
From AffDomain a with(nolock)  
	inner join dbo.AffAdmin_f_AdminUserInfo_Select('',@LicenseeID) b on a.Creator = b.UserID  
where DomainId = @DomainId
order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffSelById] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainAffSelById] TO [vnteam] AS [dbo]