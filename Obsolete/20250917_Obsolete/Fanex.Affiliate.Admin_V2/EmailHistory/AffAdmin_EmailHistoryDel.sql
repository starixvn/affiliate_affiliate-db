/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_EmailHistoryDel]  
	@listmid varchar(4000)=null,  
	@UserID int,  
	@IP varchar(20),  
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT
AS

/*  
	Created: 20090626@VinhTrinh  
	Task: Delete affiliate email by list of mail id  
	DB: DBAFF
	Original:  
  
	Revisions:  
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180205@Percy: Remove check UserId [RedmineID: #90545]

	Param's Explanation:  
		• @listmid : list of mail id separated by a comma
		• @UserID: user deleting mid will be logged
*/  

BEGIN  
	SET NOCOUNT ON  

	-- Check list of mail id
	IF (@listmid IS NULL)
	BEGIN  
		SELECT @ErrCode = 6 -- Invalid mail ID
		RETURN
	END

	DECLARE @midTable TABLE (mid INT)
	
	INSERT INTO @midTable (mid)
	SELECT DISTINCT CONVERT(INT, val) FROM dbo.strsplit(@listmid, ',')

	DECLARE @count INT, @countDB INT  
	
	SELECT @count = COUNT(1) FROM @midTable

	SELECT @countDB = COUNT(1)
	FROM EmailHistory a WITH(NOLOCK)
		INNER JOIN @midTable t ON a.mid = t.mid  
      
	IF (@count <> @countDB)  
	BEGIN  
		SELECT @ErrCode = 7 -- the selected email(s) are invalid.
		RETURN
	END      

	DELETE EmailHistory WITH(ROWLOCK, UPDLOCK)
	WHERE mid IN (SELECT mid FROM @midTable)
  
	IF @@ERROR <> 0  
	BEGIN  
		SELECT @ErrCode = 9 -- Email unsuccessfully deleted!
		RETURN
	END  
  
	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Delete EmailHistory Mail ID list:' + dbo.Aff_ToString(@listmid)  
  
	EXEC [dbo].[Aff_WriteLog]  
		@Creator = @UserId,   
		@TypeName = 'Email',   
		@SPName = @SPName,  
		@IP = @IP,  
		@Details = @Detail
END
GO