/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainMemSelById]  
   @DomainId INT
AS

/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]
*/

BEGIN
	SET NOCOUNT ON

	Select a.DomainID, a.DomainName
	From [MemberDomain] a with(nolock)  
	where DomainId = @DomainId
	order by a.DomainName
END
GO