/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ITAdminUser_Update]
	@UserID		INT,
	@UserPwd	VARCHAR(50) = NULL,
	@UserSalt	VARCHAR(50) = NULL,
	@FirstName	NVARCHAR(50) = NULL,
	@LastName	NVARCHAR(50) = NULL,
	@Status		VARCHAR(30) = NULL
AS

/*
	Created: 20151125@Victor
	DB: DBCUST.bodb_licensee
	Remark: Update IT Admin user
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON
	
	UPDATE dbo.Users WITH (ROWLOCK, UPDLOCK)
	SET UserPwd		= ISNULL(@UserPwd, UserPwd),
		UserSalt	= ISNULL(@UserSalt, UserSalt),
		FirstName	= ISNULL(@FirstName, FirstName),
		LastName	= ISNULL(@LastName, LastName),
		[Status]	= ISNULL(@Status, [Status])
	WHERE UserID	= @UserID
END
GO