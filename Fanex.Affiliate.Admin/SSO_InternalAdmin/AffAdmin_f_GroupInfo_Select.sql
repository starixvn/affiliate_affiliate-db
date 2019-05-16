/*<info serverAlias="DBCUST-bodb_Licensee" selecters="bodbAdminNet,bodbLicenseeNet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_GroupInfo_Select]
(		
	@GroupID	INT,
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
	SELECT GroupID, LicenseeID, GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator
	FROM dbo.Aff_GroupInfo WITH (NOLOCK) 
	WHERE (ISNULL(@GroupID,'') = '' OR GroupID = @GroupID)
		AND (ISNULL(@LicenseeID,'') = '' OR LicenseeID = @LicenseeID)
GO