/*<info serverAlias="DBCUST-bodb_Licensee" selecters="bodbAdminNet,bodbLicenseeNet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[Aff_f_Con_IsAllowByUserID]
(
	@LicenseeID INT,
	@CustID		INT, 
	@FuncID		INT
)

RETURNS TABLE
AS

/*
	Created: 20190424@Percy
	Task: Check permission by CustID and LicenseeID and FunctionID
	DB: DBCUST.bodb_Licensee
	
	Revisions:
		- 20190424@Percy: Initiliaze function [RedmineID: #103658]
*/

RETURN
	SELECT (ISNULL(mp.policy, 0) | ISNULL(gp.policy, 0)) & ISNULL(fi.FunctionRender, 0) AS IsAllow
	FROM dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID) ac
		LEFT JOIN dbo.AffAdmin_f_FunctionInfo_Select(@FuncID, @LicenseeID) fi ON fi.FunctionID = @FuncID
		LEFT JOIN dbo.AffAdmin_f_UserPolicy_Select(@CustID, @LicenseeID, @FuncID) mp ON mp.userid = ac.userid AND mp.functionid = @FuncID
		LEFT JOIN dbo.AffAdmin_f_GroupPolicy_Select('', @FuncID) gp ON gp.groupid = ac.groupid AND gp.functionid = @FuncID
	WHERE ac.[Status] = 0
GO