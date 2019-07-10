/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoUpd]
	@GroupID	INT,
	@LicenseeID INT,
	@GroupName	NVARCHAR(50) = NULL,
	@GroupDesc	NVARCHAR(50) = NULL,
	@Language	VARCHAR(5) = 'en-US', 
	@ErrCode	INT = 0 OUTPUT,
	@UserID		INT,
	@IP			VARCHAR(15) = ''
AS

/*
	DB: DBAFF.Affiliate_XXX

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151113@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_GroupInfo_Select
							AffAdmin_GroupInfo_Update
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @tblGroups TABLE (GroupID INT, GroupName NVARCHAR(50))

	SELECT @sql = 'SELECT GroupID, GroupName FROM OPENQUERY(DBCUST,
								''SELECT GroupID, GroupName FROM bodb_Licensee.dbo.AffAdmin_f_GroupInfo_Select('''''''',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @tblGroups (GroupID, GroupName)
	EXEC (@sql)

	IF EXISTS (SELECT 1 FROM @tblGroups WHERE GroupName = @GroupName AND GroupID <> @GroupID)
	BEGIN
		SELECT @ErrCode = 21
		RETURN
	END
		
	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_GroupInfo_Update @GroupID = @GroupID, @GroupName = @GroupName, @GroupDesc = @GroupDesc, @Creator = @UserID
		
	DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT @LogData = '[AFFILIATE] Update groupinfo:' + dbo.Aff_ToString(@GroupID)

	EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=0,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP=@IP,
		@Details=@LogData
END
GO