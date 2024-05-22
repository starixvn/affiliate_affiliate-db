/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Created: 20240521@Eddie
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Task: manual run job  [Redmine: #205233]
*/

EXEC [dbo].[Task_Aff_MonthlyTransfer_Job]
	@Month = 4,
	@Year = 2024
GO


