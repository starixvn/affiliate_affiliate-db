/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20240412@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Create new table to store needed data [RedmineId : #203782]
*/

CREATE TABLE [dbo].[StorageTable](
	[Affiliate] [NVARCHAR](50) NULL,
	[MonthDate] [SMALLDATETIME] NULL,
	[Description] [VARCHAR](12) NOT NULL,
	[TotalClick] [INT] NOT NULL,
	[UniqueClick] [INT] NOT NULL,
	[Signup] [INT] NOT NULL,
	[FDM] [INT] NOT NULL,
	[Turnover] [MONEY] NOT NULL,
	[Winlost] [MONEY] NOT NULL,
	[CommissionRate] [FLOAT] NOT NULL,
	[Earning] [MONEY] NOT NULL
) ON [PRIMARY]
GO