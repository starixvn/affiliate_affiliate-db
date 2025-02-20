/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_EmailHistory_Del]
	@MIds VARCHAR(4000) = NULL
	,@UserId	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Affiliate - Email History - Delete Email by list of ID

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250219@Eddie: New permission [RedmineID: #212201]

	Param's Explanation:
		- @MIds: List of Mail ID
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	SELECT @MIds = ISNULL(@MIds, ''), @ErrCode = 0, @ErrMsg = ''

	IF @MIds = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid mail ID!'
		RETURN
	END

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustID		= @UserId
		,@FuncName	= '[EmailHistory]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.Affiliate_User WITH (NOLOCK) WHERE CustID = @UserId)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, Admin ID is invalid. Please recheck it again.'
		RETURN
	END
	-- End check permission

	DECLARE @tblMailID TABLE (MID INT NOT NULL PRIMARY KEY, ID INT IDENTITY(1, 1))
	INSERT INTO @tblMailID (MID)
	SELECT DISTINCT val FROM dbo.Aff_f_StringSplit (@MIds, ',')
	OPTION(MAXRECURSION 0)

	IF EXISTS (
		SELECT 1
		FROM @tblMailID tmp
			OUTER APPLY (
				SELECT MID
				FROM dbo.EmailHistory e WITH (NOLOCK)
				WHERE tmp.MID = e.MID
					AND ISNULL(IsDeleted, 0) = 0
			) AS e
		WHERE e.MID IS NULL
	)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, your input mail id is invalid. Please recheck it again.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.EmailHistory WITH (ROWLOCK, UPDLOCK)
		SET IsDeleted = 1
		WHERE MID IN (SELECT MID FROM @tblMailID)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 1001, @ErrMsg = 'Error! Email unsuccessfully deleted!'
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(200), @SPName VARCHAR(50), @Content NVARCHAR(MAX), @Sender NVARCHAR(100), @AffId INT, @Email NVARCHAR(50),@Subject NVARCHAR(2000), @SendDate DATETIME
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @ID INT = 1, @_Mid INT

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM @tblMailID WHERE ID = @ID)
			RETURN

		SELECT @_Mid = MID FROM @tblMailId WHERE ID = @ID

		SELECT @Content = Content, @Sender = Sender, @Subject = Subject, @Email = Email, @SendDate = CreatedDate, @AffId = AffId
		FROM dbo.EmailHistory WITH (NOLOCK)
		WHERE MID = @_Mid
	
		SELECT @LogData = CONVERT(NVARCHAR(MAX), 
						  (
								SELECT 
									@_Mid    AS '@Mid',
									@Content AS '@Content',
									@Sender AS '@Sender', 
									@Subject AS '@Subject', 
									@Email AS '@Email', 
									CONVERT(VARCHAR(100), @SendDate, 121) AS '@SendDate'
								FOR XML PATH('row'), ROOT('root'))
						   )

		SET @AffId = CASE WHEN @AffId = -1 THEN 0 ELSE @AffId END

		EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
			 @UserId	= @UserId
			 ,@AffId	= @AffId
			 ,@SPName	= @SPName
			 ,@OldData	= @LogData
			 ,@NewData	= ''
			 ,@IP		= @IP
			 ,@Language	= @Language

		SET @ID += 1
	END
END
GO