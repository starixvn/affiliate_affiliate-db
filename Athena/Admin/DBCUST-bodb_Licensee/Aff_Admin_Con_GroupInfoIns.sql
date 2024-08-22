/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Con_GroupInfoIns]
	@LicenseeID INT,
	@GroupName	NVARCHAR(50) = '',
	@GroupDesc	NVARCHAR(50) = '',
	@UserID		INT,
	@ErrCode	INT = 0 OUTPUT,
	@GroupID	INT = 0 OUTPUT

AS

/*
	Created: 20240819@Sally
	DB: DBCUST-bodb_Licensee
	Task: Remove linked server to DBCust
	Orig: DBAFF-Affiliate_Athena000/dbo.AffAdmin_Con_GroupPolicySel

	Revisions:
		- 20240805@Sally: Initialize SP [RedmineID: #206891]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @IsExistGroupName BIT = 0
	DECLARE @tblGroups TABLE (GroupName NVARCHAR(50))

	SELECT @IsExistGroupName = 1 
	FROM dbo.AffAdmin_f_GroupInfo_Select('', @LicenseeID) 

	INSERT INTO @tblGroups (GroupName)
	EXEC (@sql)

	IF (@IsExistGroupName = 1) 
	BEGIN
		SELECT @ErrCode = 21
		RETURN
	END	

	DECLARE @NewGroupID INT = 0 
	DECLARE @Today DATETIME
	SET @Today = GETDATE()

	DECLARE @FuncIDs VARCHAR(1000)

	SELECT @FuncIDs = COALESCE(@FuncIDs + ', ', '') + CONVERT(VARCHAR(10), FunctionID) 
	FROM dbo.AffAdmin_f_FunctionInfo_Select('', @LicenseeID)

	EXEC dbo.AffAdmin_GroupInfo_Insert @LicenseeID = @LicenseeID, @GroupName = @GroupName, @GroupDesc = @GroupDesc, @CreateDate = @Today, @ModifyDate = @Today, @Creator = @UserID, @DisplayOrder = 1, @GroupID = @NewGroupID OUTPUT

	EXEC dbo.AffAdmin_GroupPolicy_Insert @GroupID = @NewGroupID, @FunctionIDs = @FuncIDs, @Policy = 0, @Creator = @UserID

	IF @@ERROR <> 0
	BEGIN
		EXEC dbo.AffAdmin_GroupInfo_Delete @GroupID = @NewGroupID
		
		SELECT @ErrCode = 12
		RETURN
	END

	SELECT @GroupID = @NewGroupID

END
GO
