ALTER FUNCTION [dbo].[AffAdmin_f_IsITAdmin]
(
	@UserID INT,
	@LicenseeID INT
)
/*
	Created: 20151109@Victor
	DB: DBAFF - Affiliate database
	Remark: Is IT Admin account
	Revision:
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
*/
RETURNS INT
AS
BEGIN
	DECLARE @IsITAdmin int = 0
	DECLARE @ITGroupID int = 0
	SELECT @ITGroupID = GroupID 
	FROM DBLIC.bodb_licensee.dbo.Aff_GroupInfo WITH (NOLOCK) 
	WHERE LicenseeID = @LicenseeID AND GroupName LIKE 'Aff_IT_Dept'

	SELECT @IsITAdmin = CASE WHEN lu.GroupID = @ITGroupID THEN 1 ELSE 0 END
	FROM bodb_licensee.dbo.Aff_LicenseeUser lu WITH (NOLOCK) 
	WHERE lu.LicenseeID = @LicenseeID AND lu.UserID = @UserID AND lu.IsActive = 1

	RETURN @IsITAdmin
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_f_IsITAdmin] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_IsITAdmin] TO [vnteam]