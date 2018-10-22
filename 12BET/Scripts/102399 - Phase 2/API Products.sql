USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new table for import from API
*/

CREATE TABLE [dbo].[APIProductSettings]
(
	ProductId		INT,
	SettingName		VARCHAR(200),
	SettingValue	VARCHAR(200),
	CONSTRAINT [PK_APIProductSettings] PRIMARY KEY CLUSTERED
	(
		ProductId ASC,
		SettingName ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [SettingData]
) ON [SettingData]
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (9, 'LastQueueId', '1')