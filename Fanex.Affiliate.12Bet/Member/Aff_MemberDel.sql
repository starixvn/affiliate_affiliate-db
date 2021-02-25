/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_MemberDel] 
	@IBCCustID		INT
	,@UserID		INT
	,@IP			VARCHAR(20)
	,@AffID			INT = NULL OUTPUT
	,@RefNo			BIGINT = 0 OUTPUT
	,@DepositCustID INT = 0 OUTPUT
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20090910@Peter
	Task : Remove a member  from Affiliate
	DB: DB052.Affiliate_12BET

	Revisions:
		Peter@20100413 : Remove the calling to sp [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
						coz AffiliateID in custinfo will be removed.  
		Johnny@20100512: Re-calculate AffDaily if member is removed.
		Peter@20100927 : Add OddsFee column for AffDetail
		- 20140424@Bobby: formating code
		- 20210225@Percy: Change role permission & remove unused code [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permisison
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AffMemberDetail]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-----------------------------------------------
	--Check IBCCustID
	SELECT @AffId = AffId
		,@DepositCustID = DepositCustID
	FROM MemberInfo(NOLOCK)
	WHERE IBCCustID = @IBCCustID
		AND IsRemoved = 0

	IF (@AffID IS NULL)
	BEGIN
		SELECT @ErrMsg = 'This member does not exist or be removed before!'
			,@ErrCode = 1001
		RETURN
	END
	
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)
		,@FirstDayOfTheMonth SMALLDATETIME

	SELECT @LogData = 'Remove member. IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
		,@FirstDayOfTheMonth = dateadd(m, datediff(m, 0, Current_Timestamp), 0)

	BEGIN TRY
		UPDATE MemberInfo WITH (ROWLOCK)
		SET IsRemoved = 1
		WHERE IBCCustID = @IBCCustID

		INSERT INTO MemberRemoval (IBCCustID, RemovedDate, RemovedBy)
		VALUES (@IBCCustID, current_timestamp, @UserID)
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'Remove member failed!'
			,@ErrCode = 1002
		RETURN
	END CATCH

	--Write the log 
	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserID
		,@AffID = @AffID
		,@Typename = 'Member'
		,@SPName = @SPName
		,@RefNo = @RefNo
		,@IP = @IP
		,@Details = @LogData
END
GO