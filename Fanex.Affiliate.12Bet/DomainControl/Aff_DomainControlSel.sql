ALTER PROCEDURE [dbo].[Aff_DomainControlSel] 
	@MarketId NVARCHAR(10) = NULL
	,@DeviceType TINYINT = 0
	,@IsDeleted BIT = 0
AS
/*
Created: 20121115@Johnny.Trinh
Task : Select Domain Control
DB: DB052.Affiliate_12BET
Revisions:
	- 20140707@Bobby: Include DeviceType info
*/
BEGIN
	SET NOCOUNT ON;

	SELECT a.Id
		,d.MarketId
		,d.MarketName
		,b.DomainId AS AffDomainId
		,b.DomainName AS AffDomain
		,c.DomainId AS RedirectDomainId
		,c.DomainName  AS RedirectDomain
		,a.CreateDate
		,e.Username AS Creator
		,a.[Status]
		,[dbo].[Aff_GetDeviceType](a.DeviceType) DeviceType
	FROM AffDomainControl a WITH (NOLOCK)
		INNER JOIN AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
		INNER JOIN [12BetDomain] c WITH (NOLOCK) 
			ON a.[12BetDomainId] = c.DomainId AND a.DeviceType = c.DeviceType
		INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
		INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
	WHERE ISNULL(@MarketId, a.MarketID) = a.MarketID
		AND a.DeviceType = @DeviceType
		AND a.IsDeleted = @IsDeleted
	ORDER BY d.MarketName
		,c.DeviceType
		,b.DomainName
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainControlSel] TO [bodbAdminNet]
GO
