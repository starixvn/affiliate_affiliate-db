/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainAffUpd]  
	@LicenseeID INT,
	@DomainID int,  
	@DomainName nvarchar(50),    
	@UserID int,    
	@IP nvarchar(15)='',  
	@ErrCode int = 0 OUTPUT
AS
  
/*  
	Created: 20121115@ThaiTran  
	Task: Update a AffDomain  
	DB: DBAFF
	
	Revisions:
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON  

	IF EXISTS (SELECT 1 FROM [AffDomain] WITH(NOLOCK) WHERE [DomainName] = @DomainName AND DomainID <> @DomainID)
	BEGIN
		SELECT @ErrCode = 2001
		RETURN
	END

	BEGIN TRANSACTION  
	
	UPDATE [AffDomain] WITH(ROWLOCK, UPDLOCK)
	SET  
		[ModifyDate] = GETDATE(),  
		[DomainName] = @DomainName,                
		[Creator] = @UserID  
	WHERE DomainID = @DomainID  
  
	IF @@ERROR <> 0   
	BEGIN  
		ROLLBACK TRANSACTION  
		
		SELECT @Errcode = 501 -- Error occurs.Insert unsuccessfully.
		RETURN  
	END    
  
	COMMIT TRANSACTION  
  
	--Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT @SPName = OBJECT_NAME(@@PROCID), @Detail = 'Update DomainID:' + dbo.Aff_ToString(@DomainID) + ' DomainName:' + dbo.Aff_ToString(@DomainName)
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @UserID,  
		@Typename = 'AffDomain', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO