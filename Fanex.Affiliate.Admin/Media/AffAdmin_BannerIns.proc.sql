/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_BannerIns]
	@LicenseeID INT,
	@BannerID int OUTPUT,
	@Content nvarchar(4000),	
	@Category smallint,
	@ImageType smallint, 
	@Currency smallint,
	@Size varchar(50)=NULL,
    @BannerType tinyint =1, /*0: Text, 1: Normal banner, 2: Media banner */
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(8)='en-US',
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20090331@DungTong
	Task: Add a new Banner
	DB: DBAFF
	Original:

	Revisions:
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
		• @UserID: user deleting msg will be logged
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CreatedDate DATETIME
	SELECT  @CreatedDate = CURRENT_TIMESTAMP

	DECLARE @SizeID SMALLINT
	
	IF @Size = '' OR @Size IS NULL
	BEGIN
		SELECT @Size = NULL
	END
	ELSE IF @BannerType IN (1,2)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.BannerTypes WITH(NOLOCK) WHERE Type = 'Size' AND Value = @Size)
		BEGIN
			INSERT INTO BannerTypes (Type, Value, DisplayOrder)
			VALUES ('Size', @Size, 1)
		END
	END

	IF @BannerType IN (1,2)
	BEGIN
		SELECT @SizeID = TypeID FROM dbo.BannerTypes WITH(NOLOCK) WHERE Type = 'Size' AND Value = @Size
	END

	BEGIN TRANSACTION

	INSERT INTO Banners ([Content], Category, [Language], ImageType, [Size], Currency, [Type], [LastUpdate], CreatedDate, UpdatedBy, Creator, Version)
	VALUES (@Content, @Category, @Language, @ImageType, @SizeID, @Currency, @BannerType, @CreatedDate, @CreatedDate, @UserID, @UserID, 1)
	
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = 501
		RETURN
	END

	SELECT @BannerID = @@IDENTITY

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID)
					+ ' Content:' + dbo.Aff_ToString(@Content)
					+ ' Category:' + dbo.Aff_ToString(@Category)
					+ ' Language:' + dbo.Aff_ToString(@Language)
					+ ' ImageType:' + dbo.Aff_ToString(@ImageType)
					+ ' Currency:' + dbo.Aff_ToString(@Currency)
					+ ' Size:' + dbo.Aff_ToString(@Size)
					+ ' Banner Type:' + dbo.Aff_ToString(@BannerType)

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserID,
		@Typename = 'Banner', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO