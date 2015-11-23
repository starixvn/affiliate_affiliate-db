ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoIns]
	@LicenseeID INT,
	@GroupName nvarchar(50)='',
	@GroupDesc nvarchar(50)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@UserID int,
	@IP varchar(15) = '' 
As
/*DB03.BODB02 -->DB052.Affiliate_ZZun*/
/*
	Revision:
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		-- 20151111@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/

--Check permission for account site: @phuc20080213

/*EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@System = 'AFFILIATE'
If @ErrCode <> 0
	RETURN*/
--end
SET NOCOUNT ON

IF exists (select 1 from dbo.AffAdmin_f_GroupInfo_Select('', @LicenseeID) WHERE GroupName = @GroupName)
BEGIN
	Select @ErrCode = 21
	return
END

DECLARE @NewGroupID INT = 0
DECLARE @Today DATETIME
SET @Today = GETDATE()

DECLARE @FuncIDs VARCHAR(1000)

SELECT	@FuncIDs = COALESCE(@FuncIDs + ', ', '') + CONVERT(VARCHAR(10), FunctionID)
FROM	dbo.AffAdmin_f_FunctionInfo_Select('', @LicenseeID)


EXEC DBLIC.bodb_licensee.dbo.AffAdmin_GroupInfo_Insert @LicenseeID = @LicenseeID, @GroupName = @GroupName, @GroupDesc = @GroupDesc, @CreateDate = @Today, @ModifyDate = @Today, @Creator = @UserID, @DisplayOrder = 1, @GroupID = @NewGroupID OUTPUT

EXEC DBLIC.bodb_licensee.dbo.AffAdmin_GroupPolicy_Insert @GroupID = @NewGroupID, @FunctionIDs = @FuncIDs, @Policy = 0, @Creator = @UserID

IF @@ERROR <> 0
BEGIN
	EXEC DBLIC.bodb_licensee.dbo.AffAdmin_GroupInfo_Delete @GroupID = @NewGroupID
	select @ErrCode = 12
	return
END


DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = '[AFFILIATE] add groupinfo:' + dbo.Aff_ToString(@NewGroupID)
	
EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=0,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData	



