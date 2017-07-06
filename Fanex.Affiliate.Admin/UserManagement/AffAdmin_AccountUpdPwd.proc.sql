/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AccountUpdPwd]  
	@CustID int,
	@UserID int,  
	@OldPwd nvarchar(50)=null,
	@OldSalt varchar(50)=null,
	@UserPwd nvarchar(50),   
	@UserSalt varchar(50), 
	@IP varchar(20), 
	@ErrCode int = 0 OUTPUT
AS  

/*
	DB: DBAFF

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151125@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN

	SET NOCOUNT ON

	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'
	
	IF NOT EXISTS (
		SELECT 1 FROM dbo.AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID) 
		WHERE
			1 = (CASE WHEN (@OldPwd IS NOT NULL AND UserPwd = @OldPwd) OR @OldPwd IS NULL THEN 1 ELSE 0 END)
			AND 1 = (CASE WHEN (@OldSalt IS NOT NULL AND UserSalt = @OldSalt) OR @OldSalt IS NULL THEN 1 ELSE 0 END)
	)
	BEGIN
		SELECT @ErrCode = 11
		RETURN 
	END

	EXEC DBLIC.bodb_licensee.dbo.AffAdmin_ITAdminUser_Update @UserID = @CustID, @UserPwd = @UserPwd, @UserSalt = @UserSalt

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)
  
	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'Password', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO