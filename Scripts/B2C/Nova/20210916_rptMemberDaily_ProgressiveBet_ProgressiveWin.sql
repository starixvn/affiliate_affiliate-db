/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20210916@Percy
	Task: Integrate Jackpot - Add ProgressiveBet, ProgressiveWin columns
	
	USE Affiliate_N88
	GO
	USE Affiliate_N8B
	GO
	USE Affiliate_N8G
	GO
*/


ALTER TABLE dbo.rptMemberDaily
	ADD ProgressiveBet MONEY, ProgressiveWin MONEY
GO