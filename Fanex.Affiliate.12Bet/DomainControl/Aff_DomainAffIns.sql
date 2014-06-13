ALTER PROC [dbo].[Aff_DomainAffIns] 
	@DomainName NVARCHAR(50)
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,@DomainID INT OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Add a new AffDomain
DB: DB052.Affiliate_12BET
Revisions:
	- 20140613@Bobby: check validation of @DomainName
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @UserID
		,@funcname = '[Domain]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		OR LEN(@DomainName) = 0 RETURN

	-----------------------------------------------
	SET @DomainName = RTRIM(LTRIM(@DomainName))

	IF EXISTS (
			SELECT 1
			FROM [AffDomain] NOLOCK
			WHERE DomainName = @DomainName
			)
	BEGIN
		SELECT @ErrCode = 1001
			,@ErrMsg = 'This Affiliate domain has been existed!'

		RETURN
	END

	DECLARE @CreatedDate DATETIME

	SELECT @CreatedDate = Current_Timestamp

	BEGIN TRANSACTION

	INSERT INTO [AffDomain] (
		[DomainName]
		,[CreateDate]
		,[ModifyDate]
		,[Creator]
		)
	VALUES (
		@DomainName
		,@CreatedDate
		,@CreatedDate
		,@UserID
		)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrMsg = N'Error occurs.Insert unsuccessfully.'
			,@ErrCode = 1002

		RETURN
	END

	SELECT @DomainID = @@IDENTITY

	COMMIT TRANSACTION

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Create DomainID:' + dbo.Aff_ToString(@DomainID) + ' DomainName:' + dbo.Aff_ToString(@DomainName)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'AffDomain'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainAffIns] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffIns] TO [vnteam]
