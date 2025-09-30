/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_BannerUpd]
	@LicenseeID INT,
	@BannerID int ,
	@Content nvarchar(4000)=null,
	@Category smallint=null,
	@Language varchar(8)='en-US',
	@ImageType smallint=null,
	@Size varchar(50)=null,
	@Currency smallint=null,
    @BannerType tinyint,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20090331@DungTong
	Task: Update affiliate Banners
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

	SELECT @ErrCode = 0
	
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

	UPDATE dbo.Banners WITH(ROWLOCK, UPDLOCK)
	SET 	
		LastUpdate = GETDATE(),
		UpdatedBy = @UserID,
		[Content] = COALESCE(@Content, Content),
		Category = COALESCE(@Category, Category),
		Language = COALESCE(@Language, Language),
		ImageType = COALESCE(@ImageType, ImageType),
		Size = COALESCE(@SizeID, Size),
		Currency = COALESCE(@Currency, Currency),
		Type = COALESCE(@BannerType, Type)
	WHERE BannerID = @BannerID
	
	IF @@ERROR <> 0 
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @Errcode = 502
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) 
					+ ' Content:' + dbo.Aff_ToString(@Content)
					+ ' Category:' + dbo.Aff_ToString(@Category)
					+ ' Language:' + dbo.Aff_ToString(@Language)
					+ ' ImageType:' + dbo.Aff_ToString(@ImageType)
					+ ' Size:' + dbo.Aff_ToString(@Size)
					+ ' Currency:' + dbo.Aff_ToString(@Currency)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'Banner', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO