/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
		- 20211222@Percy: Prevent adding duplicate product [RedmineID: #165777]
		- 20220601Malcolm: Prevent adding duplicate product (Bitcoin) [RedmineID: #172701]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SET @ProductName = LTRIM(RTRIM(@ProductName))

	IF ISNULL(@ProductName, '') = 'Sports Lottery' OR ISNULL(@API_ProductId, 0) = 63
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'Sports Lottery (API Product ID: 63) has been included in Sportsbook''s figures.'
		RETURN
	END

	IF ISNULL(@ProductName, '') = 'Bitcoin' OR ISNULL(@API_ProductId, 0) = 69
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'Bitcoin (API Product ID: 69) has been included in Sportsbook''s figures.'
		RETURN
	END
	
	IF ISNULL(@ProductName, '') = 'Cash Out' OR ISNULL(@API_ProductId, 0) = 25
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'Cash Out (API Product ID: 25) has been included in Sportsbook''s figures.'
		RETURN
	END
	
	-- Check exists
	IF EXISTS (SELECT 1 FROM dbo.Product WITH (NOLOCK) WHERE ProductName = @ProductName OR API_ProductId = ISNULL(@API_ProductId, 0))
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'Product Name or API Product ID is existing.'
		RETURN
	END

	DECLARE @ProductID INT

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
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END

	SELECT @ProductID = SCOPE_IDENTITY()

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Add New Product. ID= ' + dbo.Aff_ToString(@ProductID)
					+ '.BettypeList=' + ISNULL(@BettypeList, '')
					+ '.API_ProductID=' + dbo.Aff_ToString(@API_ProductID)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'Product', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END