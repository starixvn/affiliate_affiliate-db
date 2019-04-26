/*<info serverAlias="DBCUST-bodb_Licensee" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_FunctionInfo_Select]
(		
	@FunctionID INT,
	@LicenseeID INT
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
	SELECT f.FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames
	FROM dbo.Aff_FunctionInfo f WITH (NOLOCK) 
		INNER JOIN dbo.Aff_LicenseeFunction lf WITH (NOLOCK) ON f.FunctionID = lf.FunctionID 
	WHERE (ISNULL(@FunctionID, '') = '' OR f.FunctionID = @FunctionID)
		AND lf.LicenseeID = @LicenseeID
		AND lf.IsActive = 1
GO