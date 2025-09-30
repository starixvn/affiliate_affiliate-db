/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUpdAccountType] 
	@LicenseeID	INT
	,@AffIDs NVARCHAR(4000) = NULL
	,@TestLevel TINYINT
	,@UserId INT = NULL
	,@IP VARCHAR(20)
	,@ErrCode INT = 0 OUTPUT
AS

/*
	Created: 20131007@BrianDinh
	Task: Admin Change Account Type for Affiliate
	DB: DBAFF

	Revisions:
	  - 20131007@BrianDinh: Change Affiliate's Account Type 
	  - 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site	  
	  - 20170627@Percy: Remove check permission [RedmineID: #73925]
	
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	IF @AffIDs IS NULL
	BEGIN
		SET @ErrCode = 401

		RETURN
	END

	DECLARE @AffIdList TABLE (AffId INT)

	INSERT INTO @AffIdList
	SELECT CAST(val AS INT) FROM [dbo].[strSplit](@AffIDs, ',')

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET TestLevel = @TestLevel
	WHERE AffID IN (SELECT AffID FROM @AffIdList)

	-- Write the log.
	DECLARE @SPName VARCHAR(100), @LogData NVARCHAR(4000)

	SELECT @LogData = 'Assign account type TestLevel = ' + dbo.Aff_ToString(@TestLevel) + 'for AffIdList=' + dbo.Aff_ToString(@AffIDs)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID
		,@Typename = 'Account Type' -- refer to table LogType
		,@SPName = @SPName
		,@Details = @LogData
		,@IP = @IP
END
GO