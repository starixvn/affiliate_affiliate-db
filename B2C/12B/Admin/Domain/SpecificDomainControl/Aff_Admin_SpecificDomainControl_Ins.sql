/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_SpecificDomainControl_Ins]
	@AffUserName 		  NVARCHAR(MAX) = ''
	,@AffDomain 		  NVARCHAR(200) = ''
	,@AffDomainIsSSL 	  BIT
	,@RedirectDomain 	  NVARCHAR(200) = ''
	,@RedirectDomainIsSSL BIT
	,@Status 			  BIT
	,@UserId 			  INT
	,@IP 				  VARCHAR(50) = ''
	,@IsMobile	 		  BIT = 0
	,@ErrCode 			  INT = 0 OUTPUT
	,@ErrMsg 			  NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20250402@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Specific Domain Control - Insert

	Revisions:
		- 20250402@Lewis: Initialize SP [RedmineID: #221035]
		- 20250815@Eddie: Support for Mobile Only [RedmineID: #233219]
*/

BEGIN
	SET NOCOUNT ON

	-- =================
	-- Check permission
	-- =================
	EXEC [dbo].[Aff_Con_CheckPermission]
		@CustId		= @UserId
		,@funcname	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- =================
	-- Validate Param
	-- =================
	IF @AffUserName = ''
	BEGIN
		SELECT @ErrCode = 100
			  ,@ErrMsg ='AffUsername is required!'

		RETURN
	END
	
	IF @AffDomain = ''
	BEGIN
		SELECT @ErrCode = 101
			  ,@ErrMsg ='AffDomain is required!'

		RETURN
	END

	IF @RedirectDomain = ''
	BEGIN
		SELECT @ErrCode = 102
			  ,@ErrMsg ='RedirectDomain is required!'

		RETURN
	END

	DECLARE @AffInfo TABLE (ID INT IDENTITY(1,1), AffId INT, AffUserName NVARCHAR(60), AffDomainName NVARCHAR(200))

	INSERT INTO @AffInfo (AffId, AffUserName, AffDomainName)
	SELECT DISTINCT a.AffId, UPPER(s.value), @AffDomain
	FROM STRING_SPLIT(@AffUserName,',') s
		LEFT JOIN dbo.AffInfo a WITH (NOLOCK) ON s.value = a.UserName AND a.Status = 'Approved' AND a.IsRejected = 0

	IF EXISTS (SELECT 1 FROM @AffInfo WHERE AffId IS NULL)
	BEGIN
		SELECT @ErrCode = 103
			  ,@ErrMsg = 'These Affiliates ' + ISNULL(STRING_AGG(CONVERT(varchar(max), AffUserName), ', '), 'None') + ' are invalid!'
		FROM @AffInfo
		WHERE AffId IS NULL

		RETURN
	END

	IF EXISTS (
		SELECT 1 
		FROM dbo.SpecificDomainControl s WITH (NOLOCK)
			INNER JOIN @AffInfo a ON s.AffId = a.AffId
								 AND a.AffDomainName = s.AffDomainName
	)
	BEGIN
		SELECT @ErrCode = 104
			  ,@ErrMsg = 'This specific domain setting already exists for the Affiliate ' + ISNULL(STRING_AGG(CONVERT(varchar(max), AffUserName), ', '), 'None') + '!'
		FROM dbo.SpecificDomainControl s WITH (NOLOCK)
			INNER JOIN @AffInfo a ON s.AffId = a.AffId
			                     AND a.AffDomainName = s.AffDomainName

		RETURN
	END
	
	-- =================
	-- Insert SpecificDomainControl
	-- =================
	BEGIN TRY
		INSERT INTO dbo.SpecificDomainControl
		(
			AffId
			,AffDomainName
			,AffDomainIsSSL
			,LicenseeDomainName
			,LicenseeDomainIsSSL
			,Status
			,CreatedBy
			,CreatedDate
			,UpdatedBy
			,UpdatedDate
			,IsMobile
		)
		SELECT
			AffId
			,AffDomainName
			,@AffDomainIsSSL
			,@RedirectDomain
			,@RedirectDomainIsSSL
			,@Status
			,@UserId
			,GETDATE()
			,@UserId
			,GETDATE()
			,@IsMobile
		FROM @AffInfo

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 105, @ErrMsg = N'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- =================
	-- Write log
	-- =================
	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'AffId=' + STRING_AGG(CONVERT(varchar(max), AffId), ', ')
					+ ',AffDomainName=' + CONVERT(VARCHAR(200), @AffDomain)
					+ ',AffDomainIsSSL=' + CONVERT(VARCHAR(10), @AffDomainIsSSL)
					+ ',LicenseeDomainName=' + CONVERT(VARCHAR(200), @RedirectDomain)
					+ ',LicenseeDomainIsSSL=' + CONVERT(VARCHAR(10), @RedirectDomainIsSSL)
					+ ',IsMobile=' + CONVERT(VARCHAR(2), @IsMobile)
	FROM @AffInfo

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO