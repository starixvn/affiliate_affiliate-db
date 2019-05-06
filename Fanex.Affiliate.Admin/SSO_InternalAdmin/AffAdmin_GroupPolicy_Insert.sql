/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GroupPolicy_Insert]
	@GroupID		INT,
	@FunctionIDs	VARCHAR(1000),
	@Policy			TINYINT,
	@CreateDate		DATETIME = NULL,
	@ModifyDate		DATETIME = NULL,
	@Creator		INT = NULL
AS

/*
	Created: 20151112@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Insert GroupPolicy
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @FunctionList TABLE (FunctionID INT)
	INSERT INTO @FunctionList (FunctionID)
	SELECT CAST(val AS INT) FROM dbo.Lrf_f_StringSplit(@FunctionIDs, ',')

	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE()),
		@ModifyDate = ISNULL(@ModifyDate, GETDATE())
	
	INSERT INTO Aff_GroupPolicy (GroupID, FunctionID, Policy, CreateDate, ModifyDate, Creator)
	SELECT @GroupID, FunctionID, @Policy, @CreateDate, @ModifyDate, @Creator
	FROM @FunctionList
END
GO