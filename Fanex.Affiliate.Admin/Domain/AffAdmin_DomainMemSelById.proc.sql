ALTER PROCEDURE [dbo].[AffAdmin_DomainMemSelById]  
	@LicenseeID int,
   @DomainId int
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/
AS  

Select a.DomainID, a.DomainName
From [MemberDomain] a with(nolock)  
	inner join dbo.AffAdmin_f_AdminUserInfo_Select('',@LicenseeID) b on a.Creator = b.UserID
where DomainId = @DomainId
order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSelById] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemSelById] TO [vnteam] AS [dbo]