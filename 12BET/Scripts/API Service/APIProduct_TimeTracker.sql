USE [Affiliate_12BET]
GO

/*
	Created: 20190114@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new table for API Service [RedmineID: #107594] 
*/

CREATE TABLE [dbo].[APIProduct_TimeTracker]
(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NULL,
	[Currency] [int] NULL,
	[CallTime] [datetime] NULL
	CONSTRAINT [PK_APIProduct_TimeTracker] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE NONCLUSTERED INDEX IX_ProductId ON [APIProduct_TimeTracker] (ProductId) INCLUDE (Currency, CallTime) ON [ReportData]
GO