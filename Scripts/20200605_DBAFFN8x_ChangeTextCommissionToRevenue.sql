/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200605@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Change text 'Commission' to 'Revenue'
*/

/*
USE Affiliate_N88
GO

USE Affiliate_N8B
GO

USE Affiliate_N8G
GO
*/

UPDATE dbo.LogType WITH (ROWLOCK)
SET TypeName = 'RevenueGroup'
	,Description = 'Setting for Revenue Group'
WHERE TypeId = 1

UPDATE dbo.AffFunctionInfo WITH (ROWLOCK)
SET FuncName = '[RevenueGroup]'
	,FuncDesc = 'Revenue Group'
WHERE FuncId = 100006
GO