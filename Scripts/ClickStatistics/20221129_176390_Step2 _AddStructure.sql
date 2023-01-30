/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220920@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Add new columns for ClickStatistics1Sum [RedmineId : #176390]
*/

ALTER TABLE [dbo].[ClickStatistics1]
ALTER COLUMN [IP] [varchar](45) NOT NULL
GO

ALTER TABLE [dbo].[ClickStatistics1_bk]
ALTER COLUMN [IP] [varchar](45) NOT NULL
GO

ALTER TABLE dbo.ClickStatistics1Sum
ADD CountryCode	VARCHAR(2) NOT NULL DEFAULT('-') WITH VALUES
GO

ALTER TABLE ClickStatistics1Sum
DROP CONSTRAINT [PK_Affiliate_ClickStatistics1Sum]
GO

ALTER TABLE ClickStatistics1Sum
ADD CONSTRAINT [PK_Affiliate_ClickStatistics1Sum] PRIMARY KEY (Date, AffID, [DomainReferrer], DeviceType, SportCode, LanguageCode, CountryCode)
GO
