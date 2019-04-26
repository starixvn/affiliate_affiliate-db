/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_UserPolicy_Insert]
	@UserID			INT,
	@LicenseeID		INT,
	@FunctionID		INT,
	@Policy			TINYINT,
	@CreateDate		DATETIME = NULL,
	@ModifyDate		DATETIME = NULL,
	@Creator		INT = NULL
AS

/*
	Created: 20151118@Victor
	DB: DBCUST.bodb_licensee
	Remark: Insert UserPolicy
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE()),
		@ModifyDate = ISNULL(@ModifyDate, GETDATE())
	
	INSERT INTO Aff_UserPolicy (UserID, LicenseeID, FunctionID, Policy, CreateDate, ModifyDate, Creator)
	SELECT @UserID, @LicenseeID, @FunctionID, @Policy, @CreateDate, @ModifyDate, @Creator
END
GO