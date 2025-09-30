/*<info serverAlias="DBCUST-bodb_Licensee,DBLIC-bodb_Licensee" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_UserPolicy_Select]
(		
	@UserID		INT,
	@LicenseeID INT,
	@FunctionID INT
)
RETURNS TABLE
AS

/*
	Created:20151117@Victor
	Task: SSO from Internal Admin to Affiliate Admin
	DB: DBCUST.bodb_Licensee,DBLIC-bodb_Licensee

	Revisions:
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
		- 20240813@Sally: Remove linked server to DBCust [RedmineID: #206891]
*/

RETURN
	SELECT UserID, LicenseeID, FunctionID, Policy, CreateDate, ModifyDate, Creator
	FROM dbo.Aff_UserPolicy up WITH (NOLOCK) 
	WHERE (ISNULL(@UserID, '') = '' OR UserID = @UserID)
		AND (ISNULL(@LicenseeID, '') = '' OR LicenseeID = @LicenseeID)
		AND (ISNULL(@FunctionID, '') = '' OR FunctionID = @FunctionID)
GO