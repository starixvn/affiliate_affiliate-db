/*<info serverAlias="DBCUST-bodb_Licensee" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_GroupPolicy_Select]
(		
	@GroupID	INT,
	@FunctionID INT
)
RETURNS TABLE
AS

/*
	Created:20151113@Victor
	Task: SSO from Internal Admin to Affiliate Admin
	DB: DBCUST.bodb_Licensee

	Revisions:
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

RETURN
	SELECT GroupID, FunctionID, Policy, CreateDate, ModifyDate, Creator
	FROM dbo.Aff_GroupPolicy WITH (NOLOCK)
	WHERE (ISNULL(@GroupID, '') = '' OR GroupID = @GroupID)
		AND (ISNULL(@FunctionID, '') = '' OR FunctionID = @FunctionID)
GO