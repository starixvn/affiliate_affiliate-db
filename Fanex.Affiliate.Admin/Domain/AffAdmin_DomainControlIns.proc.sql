/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainControlIns]  
	@AffDomainID int,  
	@MemberDomainID int,  
	@CountryID nvarchar(10),  
	@Status bit = 1,   
	@UserID int,   
	@IP nvarchar(15)='',  
	@ErrCode int = 0 OUTPUT,
	@AdminUserName VARCHAR(50)
AS

/*  
	Created: 20121115@Johnny.Trinh  
	Task: Add a new AffDomainControl  
	DB: DBAFF
	
	Revisions:
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180208@Alex  : Support Liecnsee admin portal #90545
*/

BEGIN
	SET NOCOUNT ON  

	IF EXISTS (SELECT 1 FROM dbo.AffDomainControl WITH(NOLOCK) WHERE AffDomainID = @AffDomainID AND MemberDomainID = @MemberDomainID AND CountryID = @CountryID)
	BEGIN
		SELECT @ErrCode = 2020
		RETURN
	END
  
	DECLARE @CreatedDate DATETIME
	SELECT  @CreatedDate = CURRENT_TIMESTAMP
  
	BEGIN TRANSACTION  
	
	INSERT INTO [AffDomainControl]  
	(   
		[AffDomainID]  
		,[MemberDomainID]  
		,[CountryID]  
		,[CreateDate]  
		,[ModifyDate]  
		,[Creator]  
		,[Status]  
		,[CreatorName]
	 )  
	 VALUES  
	 (           
		@AffDomainID,  
		@MemberDomainID,  
		@CountryID,  
		@CreatedDate,  
		@CreatedDate,  
		@UserID,  
		@Status,
		@AdminUserName
	 )  
	
	IF @@ERROR <> 0  
	BEGIN  
		ROLLBACK TRANSACTION  
		
		SELECT @ErrCode = 501  
		RETURN  
	END  
  
	COMMIT TRANSACTION  
  
	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Create AffDomainID:' + dbo.Aff_ToString(@AffDomainID)
					+ ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)
					+ ' CountryID:' + dbo.Aff_ToString(@CountryID)
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @UserID,  
		@Typename = 'AffDomainControl', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO