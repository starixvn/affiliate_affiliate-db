/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainAffDel]
	@LicenseeID INT,
	@DomainID INT OUTPUT,
	@UserID INT,
	@IP NVARCHAR(15)='',
	@ErrCode INT = 0 OUTPUT
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

	IF EXISTS (SELECT 1 FROM dbo.AffDomainControl WITH(NOLOCK) WHERE [AffDomainID] = @DomainID)
	BEGIN  
		SELECT @ErrCode = 2002 -- Domain has been used
		RETURN  
	END  

	DECLARE @DomainName NVARCHAR(50)
	SELECT  @DomainName = DomainName FROM [AffDomain] WITH(NOLOCK) WHERE DomainID = @DomainID -- Store Domain name to write log

	DELETE dbo.AffDomain WITH(ROWLOCK, UPDLOCK)	WHERE DomainID = @DomainID  
  
	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT @SPName = OBJECT_NAME(@@PROCID), @Detail = 'Delete DomainID:' + dbo.Aff_ToString(@DomainID) + ' DomainName:' + dbo.Aff_ToString(@DomainName)
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @UserID,  
		@Typename = 'AffDomain', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO