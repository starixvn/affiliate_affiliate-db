/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251111@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Reproduct CPA 15-07 [RedmineID: #244130]
*/

USE [Affiliate_12B]
GO

/****** Object:  Index [IX_CustId_WinlostDate]    Script Date: 11/13/2025 5:34:22 PM ******/
CREATE NONCLUSTERED INDEX [IX_rptMemberDaily_CustId_WinlostDate_ProductId] ON [dbo].[rptMemberDaily]
(
	[CustId] ASC,
	[WinlostDate] ASC,
	ProductId ASC
)
INCLUDE( AffId
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Winloss
		,Rebate
		,Revenue
		,ProgressiveBet
		,ProgressiveWin
		,BetCount
		,DepositCount) 
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

