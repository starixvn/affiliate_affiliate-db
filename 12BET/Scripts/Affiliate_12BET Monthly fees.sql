USE [Affiliate_12BET]
GO

/*
	Created: 20180917@Percy
	DB: DBAFF12BET - Affiliate_12BET
	Task: Add new table for monthly fees
*/

CREATE TABLE [dbo].[rptAffDeduction]
(
	MonthDate		SMALLDATETIME,
	AffId			INT,
	GroupId			INT,
	ProductId		INT,
	GroupProductId	TINYINT,
	DeductionId		INT,
	Amount			MONEY,
	CONSTRAINT [PK_rptAffDeduction] PRIMARY KEY CLUSTERED
	(
		MonthDate	ASC,
		AffId		ASC,
		GroupId		ASC,
		ProductId	ASC,
		DeductionId	ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE NONCLUSTERED INDEX IX_AffId_ProductId ON [dbo].[rptAffDeduction] (AffId, ProductId)
		INCLUDE (GroupProductId, DeductionId, Amount) ON [ReportData]
GO