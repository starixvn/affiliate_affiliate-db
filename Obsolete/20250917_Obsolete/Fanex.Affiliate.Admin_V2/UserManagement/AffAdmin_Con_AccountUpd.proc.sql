/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
AS

/*
	Created by: 20080213@Phuc
	Task: Check permission for account site
	DB: DBAFF

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151127@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		 - 20190424@Percy: Change server of nested SP [RedmineID: #103658]
							AffAdmin_AdminUser_UpdateGroup
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_AdminUser_UpdateGroup @UserID = @CustID, @LicenseeID = @LicenseeID, @GroupID = @GroupID, @ModifyBy = @UserID

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'AFFILIATE UPDATE AccAdmin custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@groupid)

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserID,	
		@AffID = @CustID,
		@Typename = 'UserControl',	
		@SPName = @SPName ,		
		@IP = @IP,
		@Details = @Detail	
END
GO