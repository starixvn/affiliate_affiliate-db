/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_SelByCustID]
	@CustID INT
AS

/*
	Task : Get user info
	DB: DBAFF-Affiliate_Athena000
	Original: [Aff_Con_AdminSelByCustID]
	
	Revisions:
		- VinhTrinh@20100507: Get closed field from AdminUser instead of CustInfo 
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151127@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_GetITGroupID
							AffAdmin_f_AdminUserInfo_Select
		- 20240806@Sally: Remove linked server to DBCust [RedmineID: #206891]

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @GroupIT INT
	DECLARE @LicenseeID INT

	SELECT @LicenseeID = SValue 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE SName = 'LicenseeID'

	SELECT @GroupIT = GroupID
	FROM bodb_Licensee.dbo.AffAdmin_f_GetITGroupID(@LicenseeID)	

	SELECT UserID
		,Username
		,FirstName
		,LastName
		,GroupID
		,[Status]
		,CASE WHEN GroupId = @GroupIT THEN 1 ELSE 0 END AS IsIT
	FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID)
	
END
GO