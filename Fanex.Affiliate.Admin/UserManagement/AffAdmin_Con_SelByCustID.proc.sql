/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_SelByCustID]
	@CustID INT
AS

/*
	Task : Get user info
	DB: DBAFF.Affiliate_XXX
	Original: [Aff_Con_AdminSelByCustID]
	
	Revisions:
		- VinhTrinh@20100507: Get closed field from AdminUser instead of CustInfo 
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151127@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_GetITGroupID
							AffAdmin_f_AdminUserInfo_Select
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LicenseeID INT
	SELECT	@LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LicenseeID'

	DECLARE @sql NVARCHAR(MAX)

	DECLARE @tblGroupIT TABLE (GroupID INT)

	SELECT  @sql = 'SELECT GroupID FROM OPENQUERY(DBCUST, ''SELECT GroupID FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'
	
	INSERT INTO @tblGroupIT (GroupID)
	EXEC (@sql)

	DECLARE @GroupIT INT
	SELECT	@GroupIT = GroupID FROM @tblGroupIT
	
	SELECT  @sql =
		'SELECT userid,username,firstname,lastname,groupid,[Status], CASE WHEN ac.GroupId = ' + CONVERT(VARCHAR(10), @GroupIT) + ' THEN 1 ELSE 0 END AS IsIT
		FROM OPENQUERY(DBCUST, ''SELECT GroupID FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @CustID) + ', ' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'

	EXEC (@sql)
END
GO