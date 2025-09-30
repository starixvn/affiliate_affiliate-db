/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GroupPolicy_Update]
	@GroupID	INT,
	@FunctionID	INT,
	@Policy		TINYINT,
	@ModifyDate	DATETIME = NULL,
	@Creator	INT = NULL
AS

/*
	Created: 20151117@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Update GroupPolicy
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT @ModifyDate = ISNULL(@ModifyDate, GETDATE())

	UPDATE Aff_GroupPolicy WITH (ROWLOCK, UPDLOCK)
	SET Policy = @Policy,
		ModifyDate = @ModifyDate,
		Creator = ISNULL(@Creator, Creator)
	WHERE GroupID = @GroupID
		AND FunctionID = @FunctionID
END
GO