/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_EmailHistory_Del]
	@MIds VARCHAR(4000) = NULL
	,@UserId	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20190614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Email History - Delete Email by list of ID

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210223@Percy: Change permission function [RedmineID: #149213]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

	Param's Explanation:
		- @MIDs: List of Mail ID
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
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[EmailHistory]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.Users WITH (NOLOCK) WHERE CustId = @UserId)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, Admin ID is invalid. Please recheck it again.'
		RETURN
	END
	-- End check permission

	DECLARE @tblMailId TABLE (MId INT NOT NULL PRIMARY KEY, ID INT IDENTITY(1, 1))
	INSERT INTO @tblMailId (MId)
	SELECT DISTINCT val FROM dbo.strSplit (@MIds, ',')

	IF EXISTS (
		SELECT 1
		FROM @tblMailId tmp
			OUTER APPLY (
				SELECT MId
				FROM dbo.EmailHistory e WITH (NOLOCK)
				WHERE tmp.MId = e.MId
					AND ISNULL(IsDeleted, 0) = 0
			) AS e
		WHERE e.MId IS NULL
	)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, your input mail id is invalid. Please recheck it again.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.EmailHistory WITH (ROWLOCK)
		SET IsDeleted = 1
		WHERE MId IN (SELECT MId FROM @tblMailId)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 1001, @ErrMsg = 'Error! Email unsuccessfully deleted!'
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(200), @SPName VARCHAR(50), @Content NVARCHAR(MAX), @Sender nvarchar(100), @AffId INT, @Email nvarchar(50),@Subject nvarchar(2000), @SendDate DATETIME
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @ID INT = 1,@_Mid INT

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM @tblMailId WHERE ID = @ID)
			RETURN

		SELECT @_Mid = MId FROM @tblMailId WHERE ID = @ID

		SELECT @Content = Content, @Sender = Sender, @Subject = Subject, @Email = Email, @SendDate = CreatedDate, @AffId = AffId
		FROM EmailHistory
		where MID = @_Mid
	
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
			@UserId		= @UserId,
			@AffId		= @AffId,
			@SPName		= @SPName,
			@OldData	= @LogData,
			@NewData	= '',
			@IP			= @IP,
			@Language	= @Language

		SET @ID += 1
	END
END
GO