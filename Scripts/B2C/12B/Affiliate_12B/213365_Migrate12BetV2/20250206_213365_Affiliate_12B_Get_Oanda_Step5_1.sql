/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250206@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #212201]
		5. Get Oanda From 2008		

*/
USE Affiliate_12B
GO

UPDATE c SET SValue = '2008-03-13 19:00:00'
FROM dbo.SystemSettings c WITH (ROWLOCK, UPDLOCK) 
WHERE SName = 'LastImportedTime_ExchangeOanda'
GO