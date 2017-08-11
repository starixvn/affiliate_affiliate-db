/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_HotNewsUpd]
	@LicenseeID INT,
	@ID int,
	@important bit,
	@xml xml,	
	@IP varchar(20),
	@UserID int,
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20090310@TrangLe
	Task: Update affiliate hot news by message id
	DB: DBAFF
	Original:

	Revisions:
		- 20090819@DungTong: Add new Spanish language
		- 20090920@DungTong: Add new Vietnamese and Indonesia Language
		- 20140225@Joseph: Use xml data to update
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
	
	Param's Explanation:
		• @ID : message id input
		• @xml: xml data
		• @important: message important or not
		• @UserID: user updating msg, will be logged
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM [dbo].[News] WITH(NOLOCK) WHERE msgid = @ID)
	BEGIN
		SELECT @ErrCode = 202
		RETURN
	END

	BEGIN TRANSACTION

	UPDATE [News] WITH(ROWLOCK, UPDLOCK)
	SET
		Message_En = COALESCE(@xml.value('(/root/item[code="en-US"]/value)[1]','nvarchar(4000)'), Message_En)
		,[important] = COALESCE(@important, [important])
		,[updatedby] = COALESCE(@UserID, [updatedby])
		,updateddate = CURRENT_TIMESTAMP
	WHERE msgid = @ID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 203
		RETURN
	END

	UPDATE r WITH(ROWLOCK, UPDLOCK)
	SET ResourceValue = temp.Value
	FROM RefResources r
		INNER JOIN (
			SELECT	Tab.item.value('code[1]','varchar(100)') AS Code
					,Tab.item.value('value[1]','nvarchar(4000)') AS Value
			FROM @xml.nodes('/root/item') Tab(item)
		) AS temp ON r.LanguageCode = temp.Code
	WHERE r.RefID = 'News' AND r.ResourceKey = CAST(@ID AS VARCHAR(10))

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 204
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update Affiliate_News MsgID:' + dbo.Aff_ToString(@ID)                         

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserId,	
		@TypeName = 'Message',	
		@SPName = @SPName,
		@IP = @IP,
		@Details = @Detail
END
GO