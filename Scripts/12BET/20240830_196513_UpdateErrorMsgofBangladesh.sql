/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240830@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update table Messages [Redmine: #196513]
*/

USE Affiliate_12bet
GO

UPDATE dbo.Messages WITH (ROWLOCK, UPDLOCK)
SET MessageContentBN = MessageContentEN
GO