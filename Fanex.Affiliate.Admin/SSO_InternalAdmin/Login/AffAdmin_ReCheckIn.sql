/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ReCheckIn]    
	@On_UserID		INT,
	@IsKickedOut	BIT = 0 OUTPUT
AS

/*
	Created: 20151013@Victor
	Task: Re check in
	DB: DBCUST.bodb_Licensee
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @OUTPUT TABLE (IsKickedOut BIT)
	DECLARE @_On_UserID INT

	SET @_On_UserID = @On_UserID

	UPDATE Aff_On_User WITH (ROWLOCK)
	SET Reload_Time = GETDATE() 
	OUTPUT DELETED.IsKickedOut INTO @OUTPUT
	WHERE On_UserID = @_On_UserID

	IF @@ROWCOUNT = 0
		SELECT @IsKickedOut = 1
	ELSE IF EXISTS (SELECT 1 FROM @OUTPUT WHERE IsKickedOut = 1)
		SELECT @IsKickedOut = 1
	ELSE
		SET @IsKickedOut = 0
END
GO