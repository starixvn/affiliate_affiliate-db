/*<info serverAlias="DBCUST-bodb_Licensee,DBLIC-bodb_Licensee" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_AdminUserInfo_Select]
(		
	@UserID		INT,
	@LicenseeID INT
)
RETURNS TABLE
AS

/*
	Created:20151113@Victor
	Task: SSO from Internal Admin to Affiliate Admin
	DB: DBCUST.bodb_Licensee,DBLIC-bodb_Licensee

	Revisions:
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
		- 20240806@Sally: Remove linked server to DBCust [RedmineID: #206891]
*/

RETURN
	SELECT u.UserID, u.Username, lu.GroupID, 
		CONVERT(BIT, CASE WHEN u.Status = 'Closed' THEN 1 ELSE 0 END) AS [Status], 
		u.FirstName, u.LastName, u.UserPwd, u.UserSalt, u.CreateDate, u.Creator
		,l.LastLogin
	FROM dbo.Users u WITH (NOLOCK) 
		INNER JOIN dbo.Aff_LicenseeUser lu WITH (NOLOCK) ON lu.UserID = u.UserID AND lu.LicenseeID = @LicenseeID
		OUTER APPLY (
			SELECT MAX(LogDate) AS LastLogin
			FROM DBLOG.bodb_CustomerLog.dbo.UserLog_Login_Aff WITH (NOLOCK)
			WHERE UserID = lu.UserID
		) AS l
	WHERE (ISNULL(@UserID, '') = '' OR u.UserID = @UserID)
GO