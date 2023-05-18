/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20230327@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: add new tables and insert data [RedmineId : #180311]
*/

CREATE TABLE [dbo].[APIProductMappingSettings](
	[TpType]    [int]          NOT NULL,
	[SubItem]   [varchar](200) NOT NULL,
	[ProductId] [int]          NULL,
	CONSTRAINT [PK_APIProductMappingSettings] PRIMARY KEY CLUSTERED 
	(
		[TpType] ASC,
		[SubItem] ASC
	) ON [SettingData]
) ON [SettingData]
GO

INSERT INTO dbo.APIProductMappingSettings(TpType, SubItem, ProductId)
VALUES (9, '', 10) -- 12Opal eBet
GO

INSERT INTO dbo.APIProductSettings(ProductId, SettingName, SettingValue)
VALUES (10, 'TimeZone', '8')			-- 12Opal eBet
	   ,(10, 'ExcludeTicketStatus', '')	-- 12Opal eBet
GO