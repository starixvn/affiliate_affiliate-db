/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_DomainControlSel]
	@MarketId NVARCHAR(10) = NULL
	,@IsDeleted BIT = 0
AS

/*
	Created: 20121115@Johnny.Trinh
	Task: Select Domain Control
	DB: DBAFF12BET.Affiliate_12BET
	
	Revisions:
		- 20140707@Bobby: Include DeviceType info
	- 20180502@Walter: Remove DeviceType [#94324]
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
	FROM AffDomainControl a WITH (NOLOCK)
		INNER JOIN AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
		INNER JOIN [12BetDomain] c WITH (NOLOCK) 
			ON a.[12BetDomainId] = c.DomainId
		INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
		INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
	WHERE ISNULL(@MarketId, a.MarketID) = a.MarketID
		AND a.IsDeleted = @IsDeleted
	ORDER BY d.MarketName
		,b.DomainName
END
GO