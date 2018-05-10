/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Domain12BetSel]
AS

/*
	Created: 20121115@ThaiTran
	Task: Get 12betDomain list
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20140707@Bobby: Include DeviceType info
		- 20180504@Walter: Remove DeviceType param [#94324]
	
*/

BEGIN
	SET NOCOUNT ON;

	SELECT a.DomainID
		,a.DomainName
		,b.Username AS Creator
		,a.CreateDate
		,ISNULL(a.IsSSL, 0) AS IsSSL
	FROM [12BetDomain] a WITH (NOLOCK)
		INNER JOIN Affiliate_User b WITH (NOLOCK) 
		ON a.Creator = b.CustId
	WHERE IsDeleted = 0
	ORDER BY a.DomainName
END
GO