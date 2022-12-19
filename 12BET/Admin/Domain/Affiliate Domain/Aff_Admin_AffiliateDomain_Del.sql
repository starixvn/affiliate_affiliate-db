/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Del]
	@UserId			INT
	,@DomainId		INT
	,@IP			NVARCHAR(40) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate Domain - Delete

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20221111@Eddie: Support Block Market [RedmineId : #179537]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Domain]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg  OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF EXISTS (SELECT 1 FROM dbo.AffDomainControl WITH (NOLOCK) WHERE AffDomainId = @DomainId AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This Affiliate domain has been used!'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX), 
					   (
						  SELECT DomainId     AS '@DomainId'
								,DomainName   AS '@DomainName'
								,IsSSL        AS '@IsSSL'
								,BlockMarket  AS '@BlockMarket'
						  FROM dbo.AffDomain WITH (NOLOCK) 
						  WHERE DomainId = @DomainId AND IsDeleted = 0
						  FOR XML PATH('row'), ROOT('root')
					   ))

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Affiliate domain does not exists!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.AffDomain WITH (ROWLOCK)
		SET IsDeleted = 1
		WHERE DomainId = @DomainId
	END TRY
	BEGIN CATCH
		SELECT @Errcode = 103, @ErrMsg = N'Error occurs. Delete unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@IP		= @IP
END
GO