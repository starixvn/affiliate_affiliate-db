/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Member_RemoveStatus_Upd]
	@UserId			INT
	,@IBCCustId		INT
	,@IsRemoved		BIT
	,@DepositCustId	INT = 0 OUTPUT
	,@AffId			INT = 0 OUTPUT
	,@IP			VARCHAR(20)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20210225@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Member - Active Member - Check Status

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20231116@Eddie: Change Datatype of @Username [RedmineID: #196948]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MonthDate SMALLDATETIME
	
	-- Check permisison
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AffMemberDetail]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @UserName VARCHAR(50), @Old_IsRemoved BIT, @LogAffId INT
	SELECT  @UserName = UserName, @Old_IsRemoved = ISNULL(IsRemoved, 0), @AffId = AffId, @LogAffId = AffID, @DepositCustId = DepositCustId
	FROM dbo.MemberInfo WITH (NOLOCK)
	WHERE IBCCustId = @IBCCustId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This member does not exist!'
		RETURN
	END

	IF @Old_IsRemoved = @IsRemoved
		RETURN

	SELECT @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	BEGIN TRY
		UPDATE dbo.MemberInfo WITH (ROWLOCK)
		SET IsRemoved = @IsRemoved
		WHERE IBCCustId = @IBCCustId

		IF @IsRemoved = 0
		BEGIN
			SELECT @AffId = AffId FROM dbo.MemberRemoval WHERE IBCCustId = @IBCCustId AND MonthDate = @MonthDate
			
			DELETE dbo.MemberRemoval WITH (ROWLOCK, UPDLOCK)
			WHERE IBCCustId = @IBCCustId AND MonthDate = @MonthDate
		END
		ELSE IF @IsRemoved = 1
		BEGIN
			INSERT INTO dbo.MemberRemoval (IBCCustId, AffId, RemovedDate, MonthDate)
			VALUES (@IBCCustId, @AffId, GETDATE(), @MonthDate)

			SET @AffId = 0
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'The transaction is unsuccessful!'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @OldData VARCHAR(MAX), @NewData VARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @OldData = (SELECT @UserName AS '@UserName', @Old_IsRemoved AS 'RemoveStatus' FOR XML PATH('row'), ROOT('root'))
	SELECT  @NewData = (SELECT @UserName AS '@UserName', @IsRemoved AS 'RemoveStatus' FOR XML PATH('row'), ROOT('root'))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@SPName = @SPName
		,@UserId	= @UserId
		,@AffId		= @LogAffId
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
END
GO