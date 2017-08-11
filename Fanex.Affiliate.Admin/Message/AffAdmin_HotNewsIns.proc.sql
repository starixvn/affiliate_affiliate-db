/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_HotNewsIns]
		@LicenseeID INT,
		@important bit,
		@xml xml,
		@IP varchar(20),
		@UserID int,
		@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20090310@TrangLe
	Task: Insert message for Affiliate News
	DB: DBAFF
	Original:

	Revisions:
		- 20090819@DungTong: Add new Spanish language
		- 20090920@DungTong: Add new Vietnamese and Indonesia Language
		- 20130225@Joseph: Insert data into RefResources table
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
	
	Param's Explanation:
		• @important: message important or not
		• @xml: data containing all messages that will be inserted
		• @UserID: user inserting msg,creator, will be logged
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ID INT

	BEGIN TRANSACTION
           
	INSERT INTO [dbo].[News]
	(
		Message_En
		,[creator]
		,[posteddate]
		,[important]
	)
	VALUES
	(
		@xml.value('(/root/item[code="en-US"]/value)[1]','nvarchar(4000)')
		,@UserID
		,getdate()
		,@important
	)
           
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = 200
		RETURN
	END
	
	SELECT @ID = SCOPE_IDENTITY()
           
	INSERT INTO [RefResources]
	(
		[ResourceID]
		,[RefID]
		,[LanguageCode]
		,[ResourceKey]
		,[ResourceValue]
	)
	SELECT
		newid()
		,'News'
		,Tab.item.value('code[1]','varchar(100)')		
		,@ID
		,Tab.item.value('value[1]','nvarchar(4000)')
	FROM @xml.nodes('/root/item') Tab(item)
      
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = 201
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Insert into Affiliate_News MsgID:' + dbo.Aff_ToString(@ID)       

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserId,	
		@TypeName = 'Message',	
		@SPName = @SPName,
		@IP = @IP,
		@Details = @Detail
END
GO