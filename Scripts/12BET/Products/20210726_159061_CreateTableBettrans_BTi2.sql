/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
USE [Affiliate_12BET]
GO

/*
	Created: 20210726@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: create new bettrans_BTi2 table [RedmineID : #159061]
*/


USE Affiliate_12BET
GO

CREATE TABLE dbo.bettrans_BTi2
(
	PurchaseId BIGINT
	,UserName VARCHAR(50)
	,TotalStake	MONEY
	,ValidStake MONEY
	,PL MONEY
	,BetStatus VARCHAR(30)
	,BetSettledDate DATETIME
	,IBCCustId INT
	,WinlostDate SMALLDATETIME
	,CONSTRAINT PK_bettrans_BTi2 PRIMARY KEY NONCLUSTERED
	(
		PurchaseId ASC
	)
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_BTi2 (WinlostDate) ON ReportData
GO

