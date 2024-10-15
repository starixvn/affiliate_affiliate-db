/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Con_AccountIns] 
	@UserName		NVARCHAR(50)
	,@UserPwd		NVARCHAR(50) = ''
	,@UserSalt		VARCHAR(50) = ''
	,@CustID		INT OUTPUT
	,@UserID		INT
	,@LicenseeID	INT
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created:20240802@Eddie
	Task: Add account in User control
	DB: DBCUST.bodb_Licensee
	Original: AffAdmin_Con_AccountIns

	Revisions:
		- 20240802@Eddie : Split SP from AffAdmin_Con_AccountIns on DBAFF.Affiliate_XXX [RedmineID: #206891]
	
	Param's Explanation:
		• @ErrCode:
			= 0: super create master successfully.
			> 0: Specific Error.
		• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @AddErrCode INT = 0

	EXEC bodb_licensee.dbo.AffAdmin_ITAdminUser_Insert
		@LicenseeID = @LicenseeID
		,@Username	= @Username
		,@UserPwd	= @UserPwd
		,@UserSalt	= @UserSalt
		,@Creator	= @UserID
		,@ErrCode	= @AddErrCode OUTPUT
		,@UserID	= @CustID OUTPUT
	
	IF @AddErrCode = 1
	BEGIN
		SELECT @ErrCode = 2005, @ErrMsg = 'Error! This user is already exist.'
		RETURN
	END
	ELSE IF @AddErrCode = 2
	BEGIN
		SELECT @ErrCode = 10, @ErrMsg = 'Error! Insert new user unsuccessfully.'
		RETURN
	END

END
GO