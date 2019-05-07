/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet,bodbLicenseeNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[AffAdmin_f_IsITAdmin]
(
	@UserID		INT,
	@LicenseeID INT
)
RETURNS TABLE
AS

/*
	Created: 20151109@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Is IT Admin account
	
	Revisions:
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

RETURN
	SELECT CASE WHEN lu.GroupID = g.GroupID THEN 1 ELSE 0 END AS IsITAdmin
	FROM dbo.Aff_GroupInfo g WITH (NOLOCK)
		INNER JOIN dbo.Aff_LicenseeUser lu WITH (NOLOCK) ON g.LicenseeID = lu.LicenseeID
	WHERE g.GroupName = 'Aff_IT_Dept'
		AND lu.UserID = @UserID
		AND lu.LicenseeID = @LicenseeID
		AND lu.IsActive = 1
GO