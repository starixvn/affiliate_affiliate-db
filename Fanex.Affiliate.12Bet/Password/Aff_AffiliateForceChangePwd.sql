/****** Object:  Stored Procedure dbo.Aff_AffiliateForgotPwd    Script Date: 8/7/2010 4:23:02 AM ******/
ALTER PROCEDURE [Aff_AffiliateForceChangePwd] 
	@AffID			INT
	,@HashPwd		VARCHAR(50)
	,@ReHashPwd		VARCHAR(50)
	,@Question		NVARCHAR(100)
	,@Answer		NVARCHAR(100)
	,@IP			VARCHAR(20)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(200) = '' OUTPUT
AS
/*  
 Created: 20140212@Bobby.Nguyen:  
 Task : Force change password for EU affiliates
 DB: DB052.Affiliate_12BET  
  
 Revisions:  
	
 Param's Explanation:   
 • @Username AFF username
 • @AffID return affid  
 • @AffType return AFF's market type
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @UserName VARCHAR(30)
		, @ConfirmPwd VARCHAR(50)
		, @ForceChangePass BIT;

	IF (LEN(REPLACE(@UserName, ' ', '')) < 8) --12BETAFF[xxx]
	BEGIN
		SET @ErrCode = 101;-- username is not valid

		RETURN
	END

	SELECT TOP 1 @UserName = UserName
		,@ConfirmPwd = [Password]
		,@ForceChangePass = ISNULL(ForceChangePass, 0)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID = @AffID

	IF (@UserName IS NULL)
	BEGIN
		SET @ErrCode = 102;-- aff not exist

		RETURN
	END

	IF (@HashPwd <> @ConfirmPwd)
	BEGIN
		SET @ErrCode = 103;-- pwd not correct

		RETURN
	END

	IF(@ForceChangePass = 0)
	BEGIN
		SET @ErrCode = 105;-- pwd no need to change

		RETURN
	END

	--Process to change password
	UPDATE ai
	SET [Password] = @ReHashPwd
		,ForceChangePass = 0
	FROM dbo.AffInfo AS ai WITH (ROWLOCK, UPDLOCK)
	WHERE AffID = @AffID
		AND [Password] = @HashPwd

	If (@@ERROR = 0)
	BEGIN
		UPDATE ad
		SET Question = @Question
			,Answer = @Answer
		FROM dbo.AffDetail AS ad WITH (ROWLOCK, UPDLOCK)
		WHERE AffID = @AffID
	END

	--Process to write log
	DECLARE @SPName VARCHAR(50)
		,@LogData NVARCHAR(300)

	SELECT @LogData = 'Force change password for affiliate ID:' + dbo.Aff_ToString(@AffID)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @AffID
		,@AffID = @AffID
		,@Typename = 'Password'
		, @SPName = @SPName
		,@Details = @LogData
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateForceChangePwd] TO [bodbDownlineNet]
