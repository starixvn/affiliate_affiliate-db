/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ProductIns]
    @Updatedby int,
	@AdminUsername varchar(50),
    @ProductName nvarchar(50),    
    @Description nvarchar(100)=NULL,    
    @BettypeList nvarchar(255)=NULL,    
    @API_ProductID int=NULL,    
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
	Created: 20130123@Joseph
	Task: Insert Product
	DB: DBAFF
	Original:

	Revisions:
		- 20151221@Francis: Support SSO
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ProductID INT

	BEGIN TRANSACTION

	INSERT INTO [Product]
	(
		[ProductName]
		,[Description]
		,[Creator]
		,[CreatedDate]
		,[BettypeList]
		,[API_ProductID]
		,[CreatorName]
	)
	VALUES
	(
		@ProductName
		,@Description
		,@Updatedby
		,CURRENT_TIMESTAMP
		,@BettypeList
		,@API_ProductID
		,@AdminUsername
	)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	COMMIT TRANSACTION

	SELECT @ProductID = SCOPE_IDENTITY()

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Add New Product. ID= ' + dbo.Aff_ToString(@ProductID)
					+ '.BettypeList=' + @BettypeList
					+ '.API_ProductID=' + dbo.Aff_ToString(@API_ProductID)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'Product', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO