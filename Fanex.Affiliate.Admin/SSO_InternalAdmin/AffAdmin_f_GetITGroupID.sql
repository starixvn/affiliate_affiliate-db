ALTER FUNCTION [dbo].[AffAdmin_f_GetITGroupID]
(
	@LicenseeID INT
)
/*
	Created: 20151109@Victor
	DB: DBAFF - Affiliate database
	Remark: Get IT Group ID
	Revision:
		- 20151109@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
*/
RETURNS INT
AS
BEGIN
	DECLARE @GroupIT int
	SELECT @GroupIT = GroupID 
	FROM DBLIC.bodb_licensee.dbo.Aff_GroupInfo WITH (NOLOCK) 
	WHERE GroupName LIKE 'Aff_IT_Dept' 
		AND LicenseeID = @LicenseeID

	RETURN @GroupIT
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_f_GetITGroupID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_GetITGroupID] TO [vnteam] AS [dbo]