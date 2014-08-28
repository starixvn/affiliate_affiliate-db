ALTER PROCEDURE [dbo].[Aff_DomainAffClientSel] 
	@AffID INT
	,@DeviceType TINYINT = 0
	,@IsDeleted BIT = 0
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
	SET NOCOUNT ON;

	SELECT a.DomainID
		,a.DomainName
	FROM AffDomain a WITH (NOLOCK)
		INNER JOIN AffDomainControl b WITH (NOLOCK) 
			ON a.DomainID = b.AffDomainID
		INNER JOIN [12BetDomain] ld WITH (NOLOCK) 
			ON b.[12BetDomainID] = ld.DomainID AND b.DeviceType = ld.DeviceType
		INNER JOIN AffDetail d WITH (NOLOCK) ON b.MarketID = d.PreferredLanguage
	WHERE b.STATUS = 1
		AND d.AffID 	= @AffID
		AND b.DeviceType = @DeviceType
		AND a.IsDeleted =  @IsDeleted
		AND b.IsDeleted = @IsDeleted
		AND ld.IsDeleted = @IsDeleted
	GROUP BY a.DomainID
		,a.DomainName
	ORDER BY a.DomainName
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbDownlineNetView]
GO

