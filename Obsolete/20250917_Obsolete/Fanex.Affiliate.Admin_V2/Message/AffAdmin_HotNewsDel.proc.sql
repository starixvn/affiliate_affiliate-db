/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_HotNewsDel]
	@listmsgid varchar(4000)=null,
	@UserID int,
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20090624@VinhTrinh
	Task: Delete affiliate hot news by message id
	DB: DBAFF
	Original:

	Revisions:
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site 
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180205@Percy: Remove check UserId [RedmineID: #90545]

	Param's Explanation:
		• @listmsgid : list of message ids need to delete separated by a comma
		• @UserID: user deleting msg will be logged
*/

BEGIN
	SET NOCOUNT ON

	IF @listmsgid IS NULL
	BEGIN
		SELECT @ErrCode = 202
		RETURN
	END

	DECLARE @msgidTable TABLE (MsgID INT)
	INSERT INTO @msgidTable (MsgID)
	SELECT DISTINCT CONVERT(INT, val) FROM dbo.strsplit(@listmsgid, ',')
	
	DECLARE @count INT, @countDB INT

	SELECT  @count = COUNT(1) FROM @msgidTable
	SELECT  @countDB = COUNT(1)
	FROM dbo.News n WITH(NOLOCK)
		INNER JOIN @msgidTable t ON n.MsgID = t.MsgID
    
	IF (@count <> @countDB)
	BEGIN
		SELECT @ErrCode = 204
		RETURN
	END

	BEGIN TRANSACTION

	DELETE dbo.News WITH(ROWLOCK, UPDLOCK)
	WHERE MsgID IN (SELECT MsgID FROM @msgidTable)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 206
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Delete News MsgIDList:' + dbo.Aff_ToString(@listmsgid)

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserId,	
		@TypeName = 'Message',	
		@SPName = @SPName,
		@IP = @IP,
		@Details = @Detail
END
GO