/*
	Created: 20230209@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Create new table sum [RedmineId : #177639]
*/
----- table clickstatistics sum by countrycode 
CREATE TABLE [dbo].[CSSumByCountryCode](
	[AffID] 		  INT NOT NULL
	,[DomainReferrer] NVARCHAR(300) NOT NULL
	,[Date] 		  SMALLDATETIME NOT NULL
	,[TotalClick]     INT NULL
	,[UniqueClick]    INT NULL
	,[TotalSignup]    INT NULL
	,[TotalDeposit]   INT NULL
	,[DeviceType] 	  TINYINT NOT NULL
	,[CountryCode] 	  VARCHAR(2) NOT NULL
	,CONSTRAINT [PK_CSSumByCountryCode] PRIMARY KEY CLUSTERED 
	(
		[Date]   ASC
		,[AffID] ASC
		,[DomainReferrer] ASC
		,[DeviceType] 	ASC
		,[CountryCode]  ASC
	)
) ON [DATA]
GO

ALTER TABLE [dbo].[CSSumByCountryCode] ADD CONSTRAINT [DF_CSSumByCountryCode_DeviceType] DEFAULT ((0)) FOR [DeviceType]
GO

----- table clickstatistics sum by LanguageCode and SportCode 
CREATE TABLE [dbo].[CSSumByLanguageCodeandSportCode](
	[AffID] 		  INT NOT NULL
	,[DomainReferrer] NVARCHAR(300) NOT NULL
	,[Date] 		  SMALLDATETIME NOT NULL
	,[SportCode] 	  NVARCHAR(50)  NOT NULL
	,[LanguageCode]   NVARCHAR(10)  NOT NULL
	,[TotalClick]     INT NULL
	,[UniqueClick]    INT NULL
	,[TotalSignup]    INT NULL
	,[TotalDeposit]   INT NULL
	,[DeviceType] 	  TINYINT NOT NULL
	,CONSTRAINT [PK_CSSumByLanguageCodeandSportCode] PRIMARY KEY CLUSTERED 
	(
		[Date]   ASC
		,[AffID] ASC
		,[DomainReferrer] ASC
		,[DeviceType] 	ASC
		,[SportCode]    ASC
		,[LanguageCode] ASC
	)
) ON [DATA]
GO

ALTER TABLE [dbo].[CSSumByLanguageCodeandSportCode] ADD CONSTRAINT [DF_CSSumByLanguageCodeandSportCode_DeviceType] DEFAULT ((0)) FOR [DeviceType]
GO

    
