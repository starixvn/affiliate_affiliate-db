USE Affiliate_N8G
GO

-- 1. Add base currency setting
INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('AFF_BaseCurrencies', '51:VND,13:CNY,6:EUR,2:MYR,3:USD')


-- 2. rptMemberDaily
DROP TABLE dbo.rptMemberDaily -- no data
GO

CREATE TABLE dbo.rptMemberDaily
(
	WinlostDate	SMALLDATETIME,
	AffId INT,
	CustId INT,
	Currency INT,
	ExRate FLOAT,
	AffExRate FLOAT,
	ProductId INT,
	Deposit MONEY,
	Withdrawal MONEY,
	Bonus MONEY,
	Adjustment MONEY,
	Turnover MONEY,
	Winloss MONEY,
	CONSTRAINT [PK_rptMemberDaily] PRIMARY KEY NONCLUSTERED
	(
		WinlostDate ASC,
		CustId ASC,
		ProductId ASC
	) ON ReportData
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate_AffId_ProductId ON dbo.rptMemberDaily
(
	WinlostDate ASC,
	AffId ASC,
	ProductId ASC
) ON ReportData
GO

CREATE NONCLUSTERED INDEX IX_AffId_ProductId ON dbo.rptMemberDaily
(
	AffId ASC,
	ProductId ASC
)
INCLUDE (Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,AffExRate) ON ReportData
GO


-- 3. MemberRemoval
DROP TABLE dbo.MemberRemoval -- no data
GO

CREATE TABLE dbo.MemberRemoval
(
	CustId INT NOT NULL,
	RemovedDate	DATETIME,
	RemovedBy INT,
	CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED
	(
		CustId ASC
	) ON AffData
) ON AffData
GO