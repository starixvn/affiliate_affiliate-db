/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20230522@Sally
	DB: DBN88-bodb_N88
	Task: Affiliate - Handling BDT/ USD (72) currency [RedmineID: #188429]
	Step 2:
		Create table dbo.TpExchange to pull data TpExchange from bodb_N88
*/
--Create table dbo.TpExchange to pull data TpExchange from bodb_N88
IF OBJECT_ID (N'TpExchange', N'U') IS NULL 
BEGIN
	CREATE TABLE [dbo].[TpExchange](
		[TpExchangeId] [int] NOT NULL,
		[ExchangeId] [int] NULL,
	 CONSTRAINT [PK_TpExchange] PRIMARY KEY NONCLUSTERED 
	(
		[TpExchangeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
	) ON [ReportData]
END 
GO
