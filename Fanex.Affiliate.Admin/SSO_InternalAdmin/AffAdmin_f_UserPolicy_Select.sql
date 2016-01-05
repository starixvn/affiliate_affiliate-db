ALTER FUNCTION [dbo].[AffAdmin_f_UserPolicy_Select]
(		
	@UserID INT,
	@LicenseeID INT,
	@FunctionID INT
)
RETURNS @tbData TABLE
(
	UserID			INT,
	LicenseeID		INT,
	FunctionID		INT,
	Policy			TINYINT,
	CreateDate		DATETIME,
	ModifyDate		DATETIME,
	Creator			INT
) 
AS	
/*
Created:20151117@Victor
Task :  SSO from Internal Admin to Affiliate Admin
DB: DBAFF - Affiliate database

Revisions:
Param's Explanation:

*/

BEGIN
	SET @UserID = ISNULL(@UserID,'')
	SET @LicenseeID = ISNULL(@LicenseeID,'')
	SET @FunctionID = ISNULL(@FunctionID,'')

	INSERT INTO @tbData (UserID, LicenseeID, FunctionID, Policy, CreateDate, ModifyDate, Creator)
	SELECT UserID, LicenseeID, FunctionID, Policy, CreateDate, ModifyDate, Creator
	FROM DBLIC.bodb_licensee.dbo.Aff_UserPolicy up WITH (NOLOCK) 
	WHERE (@UserID = '' OR UserID = @UserID)
		AND (@LicenseeID = '' OR LicenseeID = @LicenseeID)
		AND (@FunctionID = '' OR FunctionID = @FunctionID)
	
	RETURN
END
GO
GRANT SELECT ON [dbo].[AffAdmin_f_UserPolicy_Select] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_UserPolicy_Select] TO [vnteam] AS [dbo]