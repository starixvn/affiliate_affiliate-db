/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DomainControlDel]  
	@LicenseeID INT,
	@Id int,
	@UserID int,
	@IP nvarchar(15) = '',  
	@ErrCode int = 0 OUTPUT
AS

/*  
	Created: 20121115@Johnny.Trinh  
	Task: Add a new AffDomainControl  
	DB: DBAFF
	
	Revisions: 
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON  

	DECLARE @AffDomainID INT, @MemberDomainID INT, @CountryID NVARCHAR(10)  
  
	SELECT @AffDomainID = AffDomainID, @MemberDomainID = [MemberDomainID], @CountryID = CountryID  
	FROM dbo.AffDomainControl WITH(NOLOCK)
	WHERE Id = @Id

	IF @AffDomainID IS NULL
	BEGIN
		SELECT @ErrCode = 2020
		RETURN
	END
  
	DELETE dbo.AffDomainControl WITH(ROWLOCK, UPDLOCK)
	WHERE Id = @Id

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 503
		RETURN
	END
  
	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Delete AffDomainID:' + dbo.Aff_ToString(@AffDomainID)
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