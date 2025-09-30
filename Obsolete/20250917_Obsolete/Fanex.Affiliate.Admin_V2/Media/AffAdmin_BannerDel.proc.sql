/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_BannerDel]
	@ListBannerID varchar(4000),
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 20090331@DungTong
	Task: Delete affiliate Banners by list of ids
	DB: DBAFF
	Original:

	Revisions:
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180205@Percy: Remove check UserId [RedmineID: #90545]

	Param's Explanation:
		• @ListBannerID : list of banner ids need to delete separated by a comma
		• @UserID: user deleting msg will be logged
*/

BEGIN
	SET NOCOUNT ON

	-- Check list of bannerID
	IF @ListBannerID IS NULL
	BEGIN
		SELECT @ErrCode = 300
		RETURN
	END

	DECLARE @bannerIDTable TABLE(BannerID INT)

	INSERT INTO @bannerIDTable (BannerID)
	SELECT DISTINCT val FROM dbo.strsplit(@ListBannerID, ',')
		INNER JOIN dbo.Banners b WITH(NOLOCK) ON b.BannerID = val AND COALESCE(b.totalrequest, 0) = 0

	DECLARE @count INT, @countDB INT
	
	SELECT  @count = COUNT(1) FROM @bannerIDTable
	
	SELECT  @countDB = COUNT(1)
	FROM dbo.Banners b WITH(NOLOCK)
		INNER JOIN @bannerIDTable t ON b.BannerID = t.BannerID
    
	IF (@count <> @countDB)
	BEGIN
		SELECT @ErrCode = 301
		RETURN
	END

	BEGIN TRANSACTION

	DELETE dbo.Banners WITH(ROWLOCK, UPDLOCK)
	WHERE BannerID IN (SELECT BannerID FROM @bannerIDTable)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 303
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Delete Banners BannerIDList:' + dbo.Aff_ToString(@ListBannerID)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'Banner', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO