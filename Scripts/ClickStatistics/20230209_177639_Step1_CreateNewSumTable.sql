/*
	Created: 20230209@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Create new table sum and ALter primary key [RedmineId : #177639]
*/
-- table clickstatistics sum by countrycode 
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
	,CONSTRAINT [PK_SumByCountryCode] PRIMARY KEY CLUSTERED
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

-- table clickstatistics sum by CountryCode and SportCode 
CREATE TABLE [dbo].[CSSumByCountryCodeandSportCode](
	[AffID] 		  INT NOT NULL
	,[Date] 		  SMALLDATETIME NOT NULL
	,[TotalClick]     INT NULL
	,[UniqueClick]    INT NULL
	,[TotalSignup]    INT NULL
	,[TotalDeposit]   INT NULL
	,[DeviceType] 	  TINYINT NOT NULL
	,[SportCode] 	  NVARCHAR(50)  NOT NULL
	,[CountryCode] 	  VARCHAR(2) NOT NULL
	,CONSTRAINT [PK_SumByCountryCodeandSportCode] PRIMARY KEY CLUSTERED 
	(
		[Date]   ASC
		,[AffID] ASC
		,[DeviceType]  ASC
		,[SportCode]   ASC
		,[CountryCode] ASC
	)
) ON [DATA]
GO

ALTER TABLE [dbo].[CSSumByCountryCodeandSportCode] ADD CONSTRAINT [DF_CSSumByCountryCodeandSportCode_DeviceType] DEFAULT ((0)) FOR [DeviceType]
GO

-- Alter primary key
ALTER TABLE [dbo].[ClickStatistics1Sum]
DROP CONSTRAINT [PK_Affiliate_ClickStatistics1Sum]
GO

ALTER TABLE [dbo].[ClickStatistics1Sum]
ADD CONSTRAINT [PK_Affiliate_ClickStatistics1Sum] PRIMARY KEY ([Date], [AffID], [DomainReferrer], [DeviceType], [SportCode], [LanguageCode])
GO



    
