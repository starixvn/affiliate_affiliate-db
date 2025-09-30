ALTER PROCEDURE [dbo].[AffAdmin_DomainControlSelById]
	@ID int
AS
SET NOCOUNT ON  

select ID,  
	CountryId,  
	AffDomainId,  
	MemberDomainId,  
	[Status]  
from AffDomainControl with (nolock)  
where ID = @ID

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlSelById] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainControlSelById] TO [vnteam]