ALTER PROCEDURE [dbo].[Aff_DomainAffSel] 
	@IsDeleted BIT = 0
AS
/*  
Created: 20111005@Johnny  
Task :   List aff domain
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20140708@Bobby : Apply Device type info
*/
BEGIN
	SELECT a.DomainID
		,a.DomainName
		,b.Username AS Creator
		,a.CreateDate
	FROM AffDomain a WITH (NOLOCK)
		INNER JOIN Affiliate_User b WITH (NOLOCK) ON a.Creator = b.CustId
	WHERE IsDeleted = @IsDeleted
	ORDER BY a.DomainName
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainAffSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffSel] TO [vnteam]
GO


