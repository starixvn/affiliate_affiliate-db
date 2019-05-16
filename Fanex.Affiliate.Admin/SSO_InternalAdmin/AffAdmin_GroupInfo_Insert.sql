/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GroupInfo_Insert]
	@LicenseeID		INT,
	@GroupName		NVARCHAR(50),
	@GroupDesc		NVARCHAR(50),
	@CreateDate		DATETIME = NULL,
	@ModifyDate		DATETIME = NULL,
	@DisplayOrder	TINYINT = 1,
	@Creator		INT = NULL,
	@GroupID		INT = NULL OUTPUT
AS

/*
	Created: 20151112@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Insert GroupInfo

	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RemineID: #103658]
*/

BEGIN
	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE()),
		@ModifyDate = ISNULL(@ModifyDate, GETDATE())

	INSERT INTO Aff_GroupInfo (LicenseeID, GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator)
	SELECT @LicenseeID, @GroupName, @GroupDesc, @CreateDate, @ModifyDate, @DisplayOrder, @Creator

	SELECT @GroupID = SCOPE_IDENTITY()
END
GO