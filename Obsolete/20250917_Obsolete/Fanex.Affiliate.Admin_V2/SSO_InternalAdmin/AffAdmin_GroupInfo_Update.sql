/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GroupInfo_Update]
	@GroupID	INT,
	@GroupName	NVARCHAR(50) = NULL,
	@GroupDesc	NVARCHAR(50) = NULL,
	@ModifyDate	DATETIME = NULL,
	@DisplayOrder	TINYINT = NULL,
	@Creator	INT = NULL
AS

/*
	Created: 20151112@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Update GroupInfo
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RemineID: #103658]
*/

BEGIN
	SELECT @ModifyDate = ISNULL(@ModifyDate, GETDATE())

	UPDATE Aff_GroupInfo WITH (ROWLOCK, UPDLOCK)
	SET GroupName = ISNULL(@GroupName,GroupName),
		GroupDesc = ISNULL(@GroupDesc, GroupDesc),
		ModifyDate = @ModifyDate,
		DisplayOrder = ISNULL(@DisplayOrder, DisplayOrder),
		Creator = ISNULL(@Creator, Creator)
	WHERE GroupID = @GroupID
END
GO