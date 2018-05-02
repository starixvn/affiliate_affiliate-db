/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_DomainAffSel] 
	@IsDeleted BIT = 0
AS

/*  
	Created: 20111005@Johnny
	Task: List aff domain
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:  
		- 20140708@Bobby: Apply Device type info
		- 20180412@Percy: Add IsSSL [RedmineID: #92544]
*/

BEGIN
	SET NOCOUNT ON

	SELECT a.DomainID
		,a.DomainName
		,b.Username AS Creator
		,a.CreateDate
		,CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.Affiliate_User b WITH (NOLOCK) ON a.Creator = b.CustId
	WHERE IsDeleted = @IsDeleted
	ORDER BY a.DomainName
END
GO