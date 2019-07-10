/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoIns]
	@LicenseeID INT,
	@GroupName	NVARCHAR(50) = '',
	@GroupDesc	NVARCHAR(50) = '',
	@Language	VARCHAR(5) = 'en-US', 
	@ErrCode	INT = 0 OUTPUT,
	@UserID		INT,
	@IP			VARCHAR(15) = '' 
AS

/*
	DB: DBAFF.Affiliate_XXX

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151111@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_GroupInfo_Select
							AffAdmin_f_FunctionInfo_Select
							AffAdmin_GroupInfo_Insert
							AffAdmin_GroupPolicy_Insert
							AffAdmin_GroupInfo_Delete
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @tblGroups TABLE (GroupName NVARCHAR(50))

	SELECT @sql = 'SELECT GroupName FROM OPENQUERY(DBCUST,
								''SELECT GroupName FROM bodb_Licensee.dbo.AffAdmin_f_GroupInfo_Select('''''''',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @tblGroups (GroupName)
	EXEC (@sql)

	IF EXISTS (SELECT 1 FROM @tblGroups WHERE GroupName = @GroupName) 
	BEGIN
		SELECT @ErrCode = 21
		RETURN
	END	

	DECLARE @NewGroupID INT = 0
	DECLARE @Today DATETIME
	SET @Today = GETDATE()

	DECLARE @FuncIDs VARCHAR(1000)
	DECLARE @tblFunctions TABLE (FunctionID INT)

	SELECT @sql = 'SELECT FunctionID FROM OPENQUERY(DBCUST,
								''SELECT FunctionID FROM bodb_Licensee.dbo.AffAdmin_f_FunctionInfo_Select('''''''',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @tblFunctions (FunctionID)
	EXEC (@sql)

	SELECT @FuncIDs = COALESCE(@FuncIDs + ', ', '') + CONVERT(VARCHAR(10), FunctionID)
	FROM @tblFunctions


	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_GroupInfo_Insert @LicenseeID = @LicenseeID, @GroupName = @GroupName, @GroupDesc = @GroupDesc, @CreateDate = @Today, @ModifyDate = @Today, @Creator = @UserID, @DisplayOrder = 1, @GroupID = @NewGroupID OUTPUT

	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_GroupPolicy_Insert @GroupID = @NewGroupID, @FunctionIDs = @FuncIDs, @Policy = 0, @Creator = @UserID

	IF @@ERROR <> 0
	BEGIN
		EXEC DBCUST.bodb_licensee.dbo.AffAdmin_GroupInfo_Delete @GroupID = @NewGroupID
		
		select @ErrCode = 12
		return
	END

	DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT @LogData = '[AFFILIATE] add groupinfo:' + dbo.Aff_ToString(@NewGroupID)
	
	EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=0,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData
END
GO