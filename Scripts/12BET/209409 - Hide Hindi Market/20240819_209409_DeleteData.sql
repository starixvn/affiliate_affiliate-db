/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240819@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data language Hindi [RedmineId : #209409]
*/
USE Affiliate_12BET
GO

DELETE FROM RoleMarket
WHERE MarketId = 'hi'
GO

DELETE FROM UserMarket
WHERE MarketId = 'hi'
GO

UPDATE AffDomainControl WITH (ROWLOCK, UPDLOCK)
SET MarketID = 'hi-IN'
WHERE IsDeleted = 0 AND MarketID = 'hi'
GO

EXEC sp_rename 'Aff_SupportBlockMarket_Sel', 'DEL_Aff_SupportBlockMarket_Sel'
GO

EXEC sp_rename 'Aff_SupportBlockMarket_Sel_xtest', 'DEL_Aff_SupportBlockMarket_Sel_xtest'
GO