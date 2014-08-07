ALTER PROCEDURE [dbo].[Aff_Domain12BetSel]
	@DeviceType TINYINT = 0
	,@IsDeleted BIT = 0
AS
/*
Created: 20121115@ThaiTran
Task : Get 12betDomain list
DB: DB052.Affiliate_12BET
Revisions:
	- 20140707@Bobby: Include DeviceType info
	
*/
BEGIN
	SET NOCOUNT ON;

	SELECT a.DomainID
		,a.DomainName
		,b.Username AS Creator
		,a.CreateDate
		,[dbo].[Aff_GetDeviceType](DeviceType) DeviceType
		,ISNULL(a.IsSSL, 0) AS IsSSL
	FROM [12BetDomain] a WITH (NOLOCK)
		INNER JOIN Affiliate_User b WITH (NOLOCK) 
		ON a.Creator = b.CustId
	WHERE DeviceType = @DeviceType
		AND IsDeleted = @IsDeleted
	ORDER BY a.DomainName
END
GO

GRANT EXECUTE ON [dbo].[Aff_Domain12BetSel] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_Domain12BetSel] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_Domain12BetSel] TO [bodbAdminNet]
GO
