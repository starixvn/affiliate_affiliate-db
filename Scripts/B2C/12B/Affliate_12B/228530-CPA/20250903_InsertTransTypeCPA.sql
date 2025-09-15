/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Insert CPA transaction types [RedmineID: #237540]
*/

USE Affiliate_12B

-- Insert CPA Earning transaction type
INSERT INTO TransType (TypeId, TypeName, TypeDesc)
VALUES (206, 'CPA Earning', 'CPA Earning');

-- Insert Sub-CPA Earning transaction type
INSERT INTO TransType (TypeId, TypeName, TypeDesc)
VALUES (207, 'Sub-CPAEarning', 'Sub-CPAEarning');


-- [AffTransSubDetail]
DROP TABLE IF EXISTS [AffTransSubDetail]
/****** Object:  Table [dbo].[AffTransSubDetail]    Script Date: 9/12/2025 3:12:06 PM ******/
CREATE TABLE [dbo].[AffTransSubDetail](
	[TransId] [bigint] IDENTITY(1,1) NOT NULL,
	[AffId] [int] NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[TransType] [smallint] NOT NULL,
	[TransDate] [datetime] NOT NULL,
	[DownlineAffId] [int] NOT NULL,
	[DownlineAmount] [money] NOT NULL,
	[CumulativeSubRate] [float] NOT NULL,
	[Amount] [money] NOT NULL,
	CONSTRAINT [PK_AffTransSubDetail] PRIMARY KEY NONCLUSTERED ([TransId]) ON [TransactionIndex]

) ON [TransactionIndex]
GO

/****** Object:  Index [IX_AffTransSubDetail_AffId_WinlostDate_TransType]    Script Date: 9/12/2025 3:12:37 PM ******/
CREATE CLUSTERED INDEX [CIX_AffTransSubDetail_AffId_WinlostDate_TransType] ON [dbo].[AffTransSubDetail]
(
	[AffId] ASC,
	[WinlostDate] ASC,
	[TransType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
GO

