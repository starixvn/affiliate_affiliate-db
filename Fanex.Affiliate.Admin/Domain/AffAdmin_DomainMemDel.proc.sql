/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainMemDel]
	@LicenseeID	INT,
	@DomainID int OUTPUT,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20121115@ThaiTran
	Task: Del a AffDomain
	DB: DBAFF
	
	Revisions:
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM dbo.AffDomainControl WITH(NOLOCK) WHERE MemberDomainID = @DomainID)
	BEGIN
		SELECT @ErrCode = 2003 -- This member domain has been used!
		RETURN
	END

	DECLARE @DomainName NVARCHAR(50)
	SELECT  @DomainName = DomainName FROM dbo.MemberDomain WITH(NOLOCK) WHERE DomainID = @DomainID

	DELETE dbo.MemberDomain WITH(ROWLOCK, UPDLOCK)
	WHERE DomainID = @DomainID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = 503
		RETURN
	END

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Delete Member Domain DomainID:' + dbo.Aff_ToString(@DomainID)
					+ ' DomainName:' + dbo.Aff_ToString(@DomainName)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'AffDomain', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO