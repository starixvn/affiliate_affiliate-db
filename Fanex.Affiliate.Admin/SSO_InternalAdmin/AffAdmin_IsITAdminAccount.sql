ALTER PROCEDURE [dbo].[AffAdmin_IsITAdminAccount]
(
	@UserID INT,
	@LicenseeID INT,
	@IsITAdmin BIT OUTPUT
)
/*
	Created: 20151117@Victor
	DB: DBAFF - affiliate database
	Remark: Check IT Admin account
	Revision:
*/
AS
BEGIN
	SELECT @IsITAdmin = dbo.AffAdmin_f_IsITAdmin(@UserID, @LicenseeID)
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_IsITAdminAccount] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_IsITAdminAccount] TO [vnteam]