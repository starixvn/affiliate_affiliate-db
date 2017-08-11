/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainMemIns]
	@LicenseeID INT,
	@DomainID int OUTPUT,
	@DomainName nvarchar(50), 	
	@UserID int,		
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20130822@Johnny
	Task: Add a new Member domain
	DB: DBAFF
	
	Revisions:
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM dbo.MemberDomain WITH(NOLOCK) WHERE DomainName = @DomainName)
	BEGIN
		SELECT @ErrCode = 2004 -- This member domain has been existed!
		RETURN
	END

	DECLARE @CreatedDate DATETIME
	SELECT  @CreatedDate = CURRENT_TIMESTAMP

	BEGIN TRANSACTION
	
	INSERT INTO [MemberDomain]
	(	
		[DomainName]
		,[CreateDate]
		,[ModifyDate]
		,[Creator]
	)
	VALUES
	(	        
		@DomainName,
		@CreatedDate,
		@CreatedDate,
		@UserID
	)
	
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = 501
		RETURN
	END

	SELECT @DomainID = @@IDENTITY

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Create Member Domain DomainID:' + dbo.Aff_ToString(@DomainID)
					+ ' DomainName:' + dbo.Aff_ToString(@DomainName)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'AffDomain', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO