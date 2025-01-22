/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_SecretKeyIns]
	@AffId		INT,
    @SecretKey  VARCHAR(50),
    @ErrCode    INT = 0 OUTPUT,
    @ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Verification Account - Insert Secret Key for User

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

	Parameter's Explanation:

*/

BEGIN
	SET NOCOUNT ON

    IF EXISTS(SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE SecretKey = @SecretKey)
    BEGIN
        SELECT @ErrCode = 101, @ErrMsg = 'Secret Key existed'
    END
    ELSE
    BEGIN
        UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET SecretKey = @SecretKey
			WHERE AffId = @AffId
    END
END
GO