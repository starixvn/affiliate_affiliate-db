/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainAffIns]  
	@LicenseeID int,
	@DomainID int OUTPUT,  
	@DomainName nvarchar(50),    
	@UserID int,    
	@IP nvarchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@AdminUserName VARCHAR(50)
AS

/*  
	Created: 20121115@ThaiTran  
	Task: Add a new AffDomain  
	DB: DBAFF
	
	Revisions:
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180208@Alex  : Support Liecnsee admin portal #90545

*/

BEGIN 
	SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM [AffDomain] WITH(NOLOCK) WHERE DomainName = @DomainName)  
	BEGIN  
		SELECT @ErrCode = 2001 -- Domain has been existed
		RETURN  
	END
  
	DECLARE @CreatedDate DATETIME  
	SELECT  @CreatedDate = CURRENT_TIMESTAMP  
  
	BEGIN TRANSACTION  
	
	INSERT INTO [AffDomain]  
	(   
		[DomainName]
		,[CreateDate]
		,[ModifyDate]
		,[Creator]    
		,[CreatorName]
	)  
	VALUES  
	(
		@DomainName,
		@CreatedDate,
		@CreatedDate,
		@UserID,
		@AdminUserName
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
	
	SELECT @SPName = OBJECT_NAME(@@PROCID), @Detail = 'Create DomainID:' + dbo.Aff_ToString(@DomainID) + ' DomainName:' + dbo.Aff_ToString(@DomainName)
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @UserID,  
		@Typename = 'AffDomain', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO