/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Domain_Sel]
	@TargetCountryCode	VARCHAR(2) = NULL
AS

/*
	Created: 20191210@Percy
	Task: List aff domain
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121973]
		- 20231121@Eddie: use TargetCountryCode [RedmineID: #181590]
		- 20240819@Eddie: Hide Hindi Market [RedmineID: #209409]
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT @TargetCountryCode = ISNULL(@TargetCountryCode, '')

	SELECT a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.AffDomainControl b WITH (NOLOCK) ON a.DomainID = b.AffDomainID
		INNER JOIN dbo.[12BetDomain] ld WITH (NOLOCK) ON b.[12BetDomainID] = ld.DomainID
	WHERE b.STATUS = 1
		AND a.IsDeleted = 0
		AND b.IsDeleted = 0
		AND ld.IsDeleted = 0
		AND b.TargetCountryCode = @TargetCountryCode
		AND b.MarketID NOT IN ('es-ES', 'hi') -- not use Spanish, Hindi
	GROUP BY a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0))
	ORDER BY a.DomainName
END
GO