USE Affiliate_N8G
GO

ALTER TABLE dbo.AffInfo
	ADD ParentAffId INT
		,AllParentAffId VARCHAR(MAX)
		,IsSuspended BIT CONSTRAINT DF_AffInfo_IsSuspended DEFAULT ((0))
		,SuspendedDate DATETIME
GO

CREATE NONCLUSTERED INDEX IX_ParentAffId ON dbo.AffInfo (ParentAffId, AffId) ON AffData
GO

ALTER TABLE dbo.AffGroupHistory
	ADD ParentAffId INT,
		AllParentAffId VARCHAR(MAX)
GO

CREATE TABLE dbo.MediaGallery
(
	MediaId			INT IDENTITY(1,1) NOT NULL
	,FileName		NVARCHAR(200) NOT NULL
	,TargetId		TINYINT
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
	,CreatedDate	DATETIME CONSTRAINT DF_MediaGallery_CreatedDate DEFAULT (GETDATE())
	,UpdatedBy		INT
	,UpdatedDate	DATETIME
	,CONSTRAINT PK_MediaGallery PRIMARY KEY NONCLUSTERED
	(
		MediaId ASC
	) ON SettingData
) ON SettingData
GO

CREATE CLUSTERED INDEX CIX_TargetId_ImageType ON dbo.MediaGallery (TargetId, ImageType) ON SettingData
GO

SET IDENTITY_INSERT dbo.MediaGallery ON
INSERT INTO dbo.MediaGallery(MediaId,FileName,TargetId,ImageType,Message,Size,Categories,SubCategories,Language,Currencies,AffTypes,DeviceTypes,Creator,CreatedDate,UpdatedBy,UpdatedDate)
SELECT BannerId,FileName,1,ImageType,Message,Size,c.ParentCategory,c.Category,Language,Currency,CONVERT(VARCHAR(20), AffType),CONVERT(VARCHAR(10), DeviceType),Creator,CreatedDate,UpdatedBy,LastUpdate
FROM dbo.Banners b WITH (NOLOCK)
	INNER JOIN dbo.Aff_f_MediaCategory_Sel() c
		ON b.Category = c.Category AND ((b.ImageType = 'Text' AND c.TypeId = 2) OR (b.ImageType <> 'Text' AND c.TypeId = 1))
SET IDENTITY_INSERT dbo.MediaGallery OFF
GO

DROP TABLE dbo.Banners
GO

DROP TABLE dbo.BannerTypes
GO

CREATE TABLE dbo.Exchange
(
	ExchangeId INT NOT NULL,
	Code VARCHAR(5), 
	ActualRate FLOAT,
	VND FLOAT,
	EUR FLOAT,
	USD FLOAT,
	CNY FLOAT,
	MYR FLOAT,
	CONSTRAINT PK_Exchange PRIMARY KEY CLUSTERED
	(
		ExchangeId ASC
	) ON SettingData
) ON SettingData
GO

DELETE FROM dbo.Market WITH (ROWLOCK, UPDLOCK)
WHERE MarketID NOT IN ('en-US','id-ID','ko-KR','th-TH','vi-VN','zh-CN','zh-TW')
GO