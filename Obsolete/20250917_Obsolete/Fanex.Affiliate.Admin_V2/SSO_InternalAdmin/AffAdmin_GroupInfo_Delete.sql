/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GroupInfo_Delete]
	@GroupID INT
AS

/*
	Created: 20151111@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Delete GroupInfo by GroupID
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RemineID: #103658]
*/

BEGIN
	DELETE dbo.Aff_GroupInfo WITH (ROWLOCK, UPDLOCK) WHERE GroupID = @GroupID
END
GO