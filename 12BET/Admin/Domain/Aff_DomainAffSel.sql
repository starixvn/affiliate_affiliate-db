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
		- 20140708@Bobby : Apply Device type info
*/

BEGIN
	SET NOCOUNT ON

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