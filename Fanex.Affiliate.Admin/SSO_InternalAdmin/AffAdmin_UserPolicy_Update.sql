/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_UserPolicy_Update]
	@UserID		INT,
	@LicenseeID INT,
	@FunctionID	INT,
	@Policy		TINYINT,
	@ModifyDate	DATETIME = NULL,
	@Creator	INT = NULL
AS

/*
	Created: 20151117@Victor
	DB: DBCUST.bodb_licensee
	Remark: Update UserPolicy
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SELECT @ModifyDate = ISNULL(@ModifyDate, GETDATE())

	UPDATE Aff_UserPolicy WITH (ROWLOCK, UPDLOCK)
	SET Policy = @Policy,
		ModifyDate = @ModifyDate,
		Creator = ISNULL(@Creator, Creator)
	WHERE UserID = @UserID
		AND FunctionID = @FunctionID
		AND LicenseeID = @LicenseeID
END
GO