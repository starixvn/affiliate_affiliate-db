/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_AdminUpdPwd]    
    @CustID			int,  
    @OldPassword	nvarchar(50),  
    @NewPassword	nvarchar(50),      
    @IP				varchar(20),   
    @ErrCode		int = 0 OUTPUT  
AS

/*
	DB: DBAFF-Affiliate_
	
	Revisions:
		- 20130913@Johnny: Admin change password by him/herself
		- 20151204@Francis: Revise sp to support AFF Admin User SSO
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_AdminUserInfo_Select
							AffAdmin_ITAdminUser_Update
*/

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LicenseeID'

	DECLARE @Users TABLE (UserPwd VARCHAR(50), UserSalt VARCHAR(50))

	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql =
	'SELECT UserPwd, UserSalt FROM OPENQUERY(DBCUST,
		''SELECT UserPwd, UserSalt FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @CustID) + ', ' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'

	INSERT INTO @Users (UserPwd, UserSalt)
	EXEC (@sql)

	IF NOT EXISTS (
		SELECT 1 FROM @Users
		WHERE 1 = (CASE WHEN (@OldPassword IS NOT NULL AND UserPwd = @OldPassword) OR @OldPassword IS NULL THEN 1 ELSE 0 END)
	)
	BEGIN
		SELECT @ErrCode = 11
		RETURN 
	END

	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_ITAdminUser_Update @UserID = @CustID, @UserPwd = @NewPassword
   
	-- Write log
	DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)    
	SELECT  @LogData = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)  
	SELECT  @SPName = OBJECT_NAME(@@PROCID)  
    
	EXEC dbo.Aff_WriteLog
		@Creator = @CustID,
		@Typename = 'Password', -- refer to table LogType
		@SPName = @SPName,
		@Details = @LogData,
		@IP = @IP
END
GO