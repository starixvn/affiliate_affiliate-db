/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
USE [Affiliate_12BET]
GO
/*
	Created: 20210615@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
*/

CREATE TABLE [dbo].[Sum_Winloss_IMEsports]
(
	PlayerId			VARCHAR(50),
	Currency			VARCHAR(10),
	BetCount 			INT,
	Turnover 			MONEY,
	ValidBet 	        MONEY,
	WinLoss 			MONEY,
	IsHousePlayer 		SMALLINT,
	FromDate 			SMALLDATETIME,
	ToDate 			    SMALLDATETIME,
	IBCCustId			INT,
	WinlostDate			SMALLDATETIME

	--CONSTRAINT [PK_bettrans_IMEsports] PRIMARY KEY NONCLUSTERED 
	--(
	--	WinlostDate ASC, IBCCustId ASC
	--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.Sum_Winloss_IMEsports (WinlostDate ASC) ON ReportData
GO

