/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoDel]
	@GroupID	INT,
	@Language	VARCHAR(5)= 'en-US', 
	@ErrCode	INT = 0 OUTPUT,
	@UserID		INT,
	@IP			VARCHAR(15) = ''
AS

/*
	DB: DBAFF.Affiliate_XXX
	
	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151022@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_AdminUserInfo_Select
							AffAdmin_GroupPolicy_Delete
							AffAdmin_GroupInfo_Delete
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LicenseeID INT
	SELECT  @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LicenseeID'

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @tblUsers TABLE (GroupID INT)

	SELECT @sql = 'SELECT GroupID FROM OPENQUERY(DBCUST,
								''SELECT GroupID FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select('''',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @tblUsers (GroupID)
	EXEC (@sql)

	IF EXISTS (SELECT 1 FROM @tblUsers WHERE GroupID = @GroupID) 
	BEGIN
		SELECT @ErrCode = 14
		RETURN
	END
	
	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_GroupPolicy_Delete @GroupID = @GroupID
	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_GroupInfo_Delete @GroupID = @GroupID

	-- Write log
	DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
	SELECT @SPName = OBJECT_NAME(@@PROCID)

	SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@groupid)
	
	EXEC [dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP=@IP,
			@Details=@LogData
END
GO