/*<info serverAlias="DBCUST-bodb_Licensee" selecters="bodbAdminNet,bodbLicenseeNet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_GetITGroupID]
(
	@LicenseeID INT
)
RETURNS TABLE
AS

/*
	Created: 20151109@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Get IT Group ID
	
	Revisions:
		- 20151109@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

RETURN
	SELECT GroupID 
	FROM dbo.Aff_GroupInfo WITH (NOLOCK)
	WHERE GroupName = 'Aff_IT_Dept' 
		AND LicenseeID = @LicenseeID
GO