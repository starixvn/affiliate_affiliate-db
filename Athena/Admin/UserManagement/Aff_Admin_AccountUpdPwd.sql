/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AccountUpdPwd]  
	@CustID			INT
	,@OldPwd		NVARCHAR(50) = NULL
	,@OldSalt		VARCHAR(50) = NULL
	,@UserPwd		NVARCHAR(50)
	,@UserSalt		VARCHAR(50)
	,@LicenseeID 	INT
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS  

/*
	Created: 20240723@Eddie
	DB: DBCUST.bodb_Licensee
	Task: Update user password

	Revisions:
		- 20240723@Eddie : Split SP from AffAdmin_AccountUpdPwd on DBAFF.Affiliate_XXX [RedmineID: #206891]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @Users TABLE (UserPwd VARCHAR(50), UserSalt VARCHAR(50))

	INSERT INTO @Users (UserPwd, UserSalt)
	SELECT UserPwd, UserSalt
	FROM AffAdmin_f_AdminUserInfo_Select(@CustID, @LicenseeID)

	IF NOT EXISTS (
		SELECT 1 FROM @Users
		WHERE 1 = (CASE WHEN (@OldPwd IS NOT NULL AND UserPwd = @OldPwd) OR @OldPwd IS NULL THEN 1 ELSE 0 END)
				AND 1 = (CASE WHEN (@OldSalt IS NOT NULL AND UserSalt = @OldSalt) OR @OldSalt IS NULL THEN 1 ELSE 0 END))
	BEGIN
		SELECT @ErrCode = 11, @ErrMsg = 'Error! Password is incorrect!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.Users WITH (ROWLOCK, UPDLOCK)
		SET UserPwd	 = @UserPwd
		  , UserSalt = @UserSalt
		WHERE UserID = @CustID
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error! Change password unsuccessfully!'
		RETURN
	END CATCH

END
GO