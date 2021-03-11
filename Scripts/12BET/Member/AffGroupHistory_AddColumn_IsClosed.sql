/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210301@Percy
	DB: DBAFF12BET-Affiliate_12BET 
	Task: AffGroupHistory - Add new column IsClosed [RedminedId: #149213]
*/
USE Affiliate_12BET
GO

ALTER TABLE dbo.AffGroupHistory
	ADD IsClosed BIT CONSTRAINT DF_AffGroupHistory_IsClosed DEFAULT ((0))
GO