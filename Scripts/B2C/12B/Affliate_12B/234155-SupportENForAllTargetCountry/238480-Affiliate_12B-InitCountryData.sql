/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250917@Sally	
	Task: Customize Target country/Language list, English for all target country
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250917@Sally: Init Country data [RedmineID: #238480]


*/

USE Affiliate_12B
GO
-- Script to insert missing countries from TargetCountry into Country table in a single query
IF OBJECT_ID('dbo.Country', 'U') IS  NULL
BEGIN
	CREATE TABLE [dbo].[Country](
		[CountryCode] [varchar](5) NOT NULL,
		[CountryName] [varchar](200) NOT NULL,
	CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED
	(
		[CountryCode] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
END

GO
-- Remove ja-JP market and JP target country
UPDATE c SET c.IsDeleted = 1 FROM dbo.Market c WITH(ROWLOCK, UPDLOCK) WHERE marketId = 'ja-JP' 
GO
DELETE c FROM dbo.TargetCountry c WITH(ROWLOCK) WHERE CountryCode = 'JP'
GO
INSERT INTO Country (CountryCode, CountryName)
SELECT DISTINCT t.CountryCode, t.CountryName
FROM TargetCountry t WITH(NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Country c WITH(NOLOCK)
    WHERE c.CountryCode = t.CountryCode
);

-- Verify the insertions
SELECT COUNT(1) AS NumOfRows FROM Country;

GO
