/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20251112@Sophia
	DB: DB12B-bodb_12B
	Task: Create ExchangeDailyOanda_Bid table for storing Oanda Bid exchange rates [RedmineId: #243773]
*/
USE bodb_12B
GO


/****** Object:  Table [dbo].[ExchangeDailyOanda_Bid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExchangeDailyOanda_Bid](
	[ExchangeDate] [SMALLDATETIME] NOT NULL,
	[ExchangeId] [INT] NOT NULL,
	[Code] [VARCHAR](12) NULL,
	[MYR] [FLOAT] NULL,
	[USD] [FLOAT] NULL,
	[EUR] [FLOAT] NULL,
	[CNY] [FLOAT] NULL,
	[IDR] [FLOAT] NULL,
	[AUD] [FLOAT] NULL,
	[CHF] [FLOAT] NULL,
	[GBP] [FLOAT] NULL,
	[SGD] [FLOAT] NULL,
	[THB] [FLOAT] NULL,
	[VND] [FLOAT] NULL,
	[KRW] [FLOAT] NULL,
	[JPY] [FLOAT] NULL,
	[HKD] [FLOAT] NULL,
	[TWD] [FLOAT] NULL,
	[PHP] [FLOAT] NULL,
	[BDT] [FLOAT] NULL,
	[INR] [FLOAT] NULL,
	[TRY] [FLOAT] NULL,
	[NPR] [FLOAT] NULL,
	[MXN] [FLOAT] NULL,
	[NGN] [FLOAT] NULL,
	[BRL] [FLOAT] NULL,
	[PKR] [FLOAT] NULL,
	[ZAR] [FLOAT] NULL,
	CONSTRAINT [PK_ExchangeDailyOanda_Bid] PRIMARY KEY CLUSTERED 
	(
		[ExchangeDate] ASC,
		[ExchangeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
