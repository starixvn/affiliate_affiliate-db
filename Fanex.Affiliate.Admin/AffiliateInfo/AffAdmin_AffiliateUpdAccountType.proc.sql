ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUpdAccountType] 
	@LicenseeID	INT
	,@AffIDs NVARCHAR(4000) = NULL
	,@TestLevel TINYINT
	,@UserId INT = NULL
	,@IP VARCHAR(20)
	,@ErrCode INT = 0 OUTPUT
AS
/*
	Created: 20131007@BrianDinh
	Task : Admin Change Account Type for Affiliate
	DB: DB052.Affiliate_MYM

	Revisions:
	  - 20131007@BrianDinh: Change Affiliate's Account Type 
	  - 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site	  
	Param's Explanation:
	• 
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
				EXEC [dbo].[Aff_Con_CheckPermission] @LicenseeID = @LicenseeID
		,@custid = @UserID
		,@funcname = '[Affiliate]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT

	IF @ErrCode <> 0 RETURN

	-----------------------------------------------
	IF @AffIDs IS NULL
	BEGIN
		SET @ErrCode = 401

		RETURN
	END

	DECLARE @AffIdList TABLE (AffId INT)

	INSERT INTO @AffIdList
	SELECT CAST(val AS INT)
	FROM [dbo].[strSplit](@AffIDs, ',')

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET TestLevel = @TestLevel
	WHERE AffID IN (
			SELECT AffID
			FROM @AffIdList
			)

	-- Write the log.
	DECLARE @SPName VARCHAR(100)
		,@LogData NVARCHAR(4000)
		,@AffId INT

	SELECT @LogData = 'Assign account type TestLevel = ' + dbo.Aff_ToString(@TestLevel) + 'for AffIdList=' + dbo.Aff_ToString(@AffIDs)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @AffId = (
			SELECT TOP 1 AffId
			FROM @AffIdList
			)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID
		,@Typename = 'Account Type'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @LogData
		,@IP = @IP
END

GRANT EXECUTE ON [dbo].[AffAdmin_UpdAffType] TO [bodbAdminNet]
