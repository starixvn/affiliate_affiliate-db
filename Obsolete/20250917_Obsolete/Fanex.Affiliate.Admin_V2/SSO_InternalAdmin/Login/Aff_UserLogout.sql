ALTER PROCEDURE [dbo].[Aff_UserLogout]
	@On_UserID INT
AS
SET NOCOUNT ON

/*
	Created: 20151013@Victor
	Task: User Logout
	DB: DBLIC/bodb_Licensee
	Original 
	
	Revisions:

*/

DELETE FROM Aff_On_User WHERE on_userid = @On_UserID

GO
GRANT EXECUTE ON [dbo].[Aff_UserLogout] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_UserLogout] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_UserLogout] TO [vnteam] AS [dbo]