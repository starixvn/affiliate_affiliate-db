ALTER  FUNCTION  [dbo].[AffAdmin_f_AdminUserInfo_Select]
(		
	@UserID INT,
	@LicenseeID INT
)
RETURNS @tbData TABLE
(
	UserID		INT,
	Username	VARCHAR(50),
	GroupID		INT,
	[Status]	BIT,
	FirstName	NVARCHAR(50),
	LastName	NVARCHAR(50),
	CreateDate DATETIME,
	Creator		INT
) 
AS	
/*
Created:20151113@Victor
Task :  SSO from Internal Admin to Affiliate Admin
DB: DBAFF - Affiliate database

Revisions:
Param's Explanation:

*/

BEGIN
	SELECT @UserID = ISNULL(@UserID, '')

	INSERT INTO @tbData (UserID, Username, GroupID, [Status], FirstName, LastName, CreateDate, Creator)
	SELECT u.UserID, u.Username, lu.GroupID, 
		CASE WHEN u.Status LIKE 'Closed' THEN 1 ELSE 0 END AS [Status], 
		u.FirstName, u.LastName, u.CreateDate, u.Creator
	FROM DBLIC.bodb_licensee.dbo.Users u WITH (NOLOCK) 
		INNER JOIN DBLIC.bodb_licensee.dbo.Aff_LicenseeUser lu WITH (NOLOCK) ON lu.UserID = u.UserID AND lu.LicenseeID = @LicenseeID
	WHERE (@UserID = '' OR u.UserID = @UserID)

	RETURN
END

GO
GRANT SELECT ON [dbo].[AffAdmin_f_AdminUserInfo_Select] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_AdminUserInfo_Select] TO [vnteam]
