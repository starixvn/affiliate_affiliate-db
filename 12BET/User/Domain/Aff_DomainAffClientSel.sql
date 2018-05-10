/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_DomainAffClientSel] 
	@AffID		INT
AS

/*  
	Created: 20111005@Johnny
	Task: List aff domain
	DB: DBAFF12BET.Affiliate_12BET
	Original:

	Revisions:
		- 20140708@Bobby: Apply Device type info
		- 20180412@Percy: Add IsSSL [RedmineID: #92544]
		- 20180504@Walter: Remove DeviceType param [#94324]
*/

BEGIN
	SET NOCOUNT ON;

	SELECT a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.AffDomainControl b WITH (NOLOCK) 
			ON a.DomainID = b.AffDomainID
		INNER JOIN dbo.[12BetDomain] ld WITH (NOLOCK) 
			ON b.[12BetDomainID] = ld.DomainID
		INNER JOIN dbo.AffDetail d WITH (NOLOCK) ON b.MarketID = d.PreferredLanguage
	WHERE b.STATUS = 1
		AND d.AffID 	= @AffID
		AND a.IsDeleted =  0
		AND b.IsDeleted = 0
		AND ld.IsDeleted = 0
	GROUP BY a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0))
	ORDER BY a.DomainName
END
GO