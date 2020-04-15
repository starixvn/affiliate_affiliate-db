USE Affiliate_12BET
GO

/*
	Created: 20200301@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: New structure for banner to support upload multiple banner

	Remark:
		1. Current tables: Banners_1, BannerTypes_1
		2. Un-used tables: Banners, BannerTypes
		--> Re-used table Banners with new structure

	Step:
		1. Rename tables Banners, BannerTypes to DEL_Banners, DEL_BannerTypes
		2. Create new table Banners (BannerTypes: no need)
		3. Initialize data from Banners_1
*/

EXEC sp_rename 'Banners', 'DEL_Banners'
GO

EXEC sp_rename 'BannerTypes', 'DEL_BannerTypes'
GO

CREATE TABLE dbo.Banners
(
	BannerId		INT IDENTITY(1,1) NOT NULL
	,FileName		VARCHAR(100) NOT NULL
	,ImageType		VARCHAR(10)
	,Message		NVARCHAR(MAX)
	,Size			VARCHAR(20)
	,Categories		VARCHAR(2000)
	,SubCategories	VARCHAR(2000)
	,Language		VARCHAR(100)
	,Currencies		VARCHAR(500)
	,AffTypes		VARCHAR(20)
	,DeviceTypes	VARCHAR(10)
	,Creator		INT
	,CreatedDate	DATETIME CONSTRAINT DF_Banners_CreatedDate DEFAULT (GETDATE())
	,UpdatedBy		INT
	,UpdatedDate	DATETIME
	,CONSTRAINT PK_Banners PRIMARY KEY CLUSTERED
	(
		BannerId ASC
	) ON DATA
) ON DATA
GO

SET IDENTITY_INSERT dbo.Banners ON
INSERT INTO dbo.Banners(BannerId,FileName,ImageType,Message,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,Creator,CreatedDate,UpdatedBy,UpdatedDate)
SELECT BannerId,FileName,ImageType,Message,Size,c.ParentCategory,c.Category,Language,Currency,CONVERT(VARCHAR(20), AffType),CONVERT(VARCHAR(10), DeviceType),Creator,CreatedDate,UpdatedBy,LastUpdate
FROM dbo.Banners_1 b WITH (NOLOCK)
	INNER JOIN dbo.Aff_f_MediaCategory_Sel() c
		ON b.Category = c.Category AND ((b.ImageType = 'Text' AND c.TypeId = 2) OR (b.ImageType <> 'Text' AND c.TypeId = 1))
SET IDENTITY_INSERT dbo.Banners OFF
GO