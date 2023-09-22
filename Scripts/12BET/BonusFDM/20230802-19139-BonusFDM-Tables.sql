/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
USE Affiliate_12BET
GO

--- TABLE: CommGroup
ALTER TABLE dbo.CommGroup ADD IsApplyBonus BIT NULL
GO
ALTER TABLE dbo.CommGroup ADD CONSTRAINT DF_CommGroup_IsApplyBonus DEFAULT 0 FOR IsApplyBonus
GO
ALTER TABLE dbo.CommGroupHistory ADD IsApplyBonus BIT NULL
GO
ALTER TABLE dbo.CommGroupHistory ADD CONSTRAINT	DF_CommGroupHistory_IsApplyBonus DEFAULT 0 FOR IsApplyBonus
GO

CREATE TABLE [dbo].[FDMTierSetting](
	[GroupId] [int] NOT NULL,
	[TierId] [int] NOT NULL,
	[MinFDM] [int] NULL,
	[MaxFDM] [int] NULL,
	[MinAmount] [money] NULL,
	[MaxAmount] [money] NULL,
	[LimitAmount] [money] NULL,
	[Commission] [decimal](9, 8) NOT NULL,
	CONSTRAINT [PK_FDMTierSetting] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[TierId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO

ALTER TABLE [dbo].[FDMTierSetting] ADD  CONSTRAINT [DF_FDMTierSetting_Commission]  DEFAULT ((0)) FOR [Commission]
GO

CREATE TABLE [dbo].[FDMTierSettingHistory](
	[GroupId] [int] NOT NULL,
	[MonthDate] [smalldatetime] NOT NULL,
	[TierId] [int] NOT NULL,
	[MinFDM] [int] NULL,
	[MaxFDM] [int] NULL,
	[MinAmount] [money] NULL,
	[MaxAmount] [money] NULL,
	[LimitAmount] [money] NULL,
	[Commission] [decimal](9, 8) NOT NULL,
	CONSTRAINT [PK_FDMTierSettingHistory] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[MonthDate] ASC,
		[TierId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


--- ADD 5 new columns on rptAffCommission
ALTER TABLE [dbo].[rptAffCommission]
ADD 
	IsApplyBonus		BIT,
	FDMCount			INT,
	FDMDeposit			MONEY,
	FDMCommissionRate	DECIMAL(9, 8),
	FDMCommission		MONEY;
GO


-- ADD 2 New Error messages
USE [Affiliate_12BET]
GO

INSERT INTO [dbo].[Messages]
           ([MessageId]
           ,[MessageTypeId]
           ,[Description]
           ,[MessageContentEN]
           ,[MessageContentCS]
           ,[MessageContentCH]
           ,[MessageContentID]
           ,[MessageContentVN]
           ,[MessageContentTH]
           ,[MessageContentKO]
           ,[MessageContentES]
           ,[MessageContentJP]
           ,[MessageContentHIEN]
           ,[MessageContentENEURO]
           ,[MessageContentKH]
           ,[MessageContentBN])
     VALUES
           (1010
           ,10
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'
           ,N'Oops, maximum of 50 FDM tiers are allowed!'),
		   (1011
           ,10
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!'
           ,N'Error! Invalid FDM Tier Setting!')
GO


