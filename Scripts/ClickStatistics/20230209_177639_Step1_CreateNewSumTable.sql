/*
	Created: 20230209@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Create new table sum[RedmineId : #177639]
*/
-- table clickstatistics sum by DomainReferrer and Countrycode 
CREATE TABLE [dbo].[CSSumByCountryCode](
	[AffID] 		  INT NOT NULL
	,[Date] 		  SMALLDATETIME NOT NULL
	,[TotalClick]     INT NULL
	,[UniqueClick]    INT NULL
	,[DeviceType] 	  TINYINT NOT NULL
	,[DomainReferrer] NVARCHAR(300) NOT NULL
	,[CountryCode] 	  VARCHAR(2) NOT NULL
	,CONSTRAINT [PK_SumByCountryCode] PRIMARY KEY CLUSTERED
	(
		[Date]   ASC
		,[AffID] ASC
		,[DeviceType]  ASC
		,[DomainReferrer] ASC
		,[CountryCode] ASC
	)
) ON [DATA]
GO

ALTER TABLE [dbo].[CSSumByCountryCode] ADD CONSTRAINT [DF_CSSumByCountryCode_DeviceType] DEFAULT ((0)) FOR [DeviceType]
GO

-- table clickstatistics sum by CountryCode and SportCode 
CREATE TABLE [dbo].[CSSumByCountryCodeandSportCode](
	[AffID] 		  INT NOT NULL
	,[Date] 		  SMALLDATETIME NOT NULL
	,[TotalClick]     INT NULL
	,[UniqueClick]    INT NULL
	,[DeviceType] 	  TINYINT NOT NULL
	,[CountryCode] 	  VARCHAR(2) NOT NULL
	,[SportCode] 	  NVARCHAR(50) NOT NULL
	,CONSTRAINT [PK_SumByCountryCodeandSportCode] PRIMARY KEY CLUSTERED 
	(
		[Date]   ASC
		,[AffID] ASC
		,[DeviceType]  ASC
		,[CountryCode] ASC
		,[SportCode]   ASC
	)
) ON [DATA]
GO

ALTER TABLE [dbo].[CSSumByCountryCodeandSportCode] ADD CONSTRAINT [DF_CSSumByCountryCodeandSportCode_DeviceType] DEFAULT ((0)) FOR [DeviceType]
GO

-- table clickstatistics sum by SportCode and LanguageCode 
CREATE TABLE [dbo].[CSSumBySportCodeandLanguageCode](
	[AffID] 		  INT NOT NULL
	,[Date] 		  SMALLDATETIME NOT NULL
	,[TotalClick]     INT NULL
	,[UniqueClick]    INT NULL
	,[DeviceType] 	  TINYINT NOT NULL
	,[SportCode] 	  NVARCHAR(50) NOT NULL
	,[LanguageCode]   NVARCHAR(10) NOT NULL
	,CONSTRAINT [PK_SumBySportCodeandLanguageCode] PRIMARY KEY CLUSTERED 
	(
		[Date]   ASC
		,[AffID] ASC
		,[DeviceType]   ASC
		,[SportCode]    ASC
		,[LanguageCode] ASC
	)
) ON [DATA]
GO

ALTER TABLE [dbo].[CSSumBySportCodeandLanguageCode] ADD CONSTRAINT [DF_CSSumBySportCodeandLanguageCode_DeviceType] DEFAULT ((0)) FOR [DeviceType]
GO