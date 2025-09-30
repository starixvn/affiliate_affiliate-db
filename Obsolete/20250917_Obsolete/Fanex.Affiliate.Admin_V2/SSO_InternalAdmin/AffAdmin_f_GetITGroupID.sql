/*<info serverAlias="DBCUST-bodb_Licensee,DBLIC-bodb_Licensee" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_GetITGroupID]
(
	@LicenseeID INT
)
RETURNS TABLE
AS

/*
	Created: 20151109@Victor
	DB: DBCUST.bodb_Licensee, DBLIC-bodb_Licensee
	Remark: Get IT Group ID
	
	Revisions:
		- 20151109@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
		- 20240806@Sally: Remove linked server to DBCust [RedmineID: #206891]
*/

RETURN
	SELECT GroupID 
	FROM dbo.Aff_GroupInfo WITH (NOLOCK)
	WHERE GroupName = 'Aff_IT_Dept' 
		AND LicenseeID = @LicenseeID
GO