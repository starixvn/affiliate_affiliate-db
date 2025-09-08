/*<info serverAlias="DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20250908@Sally
	DB: DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Update Minimum Withdrawal Amount [RedmineID: #238108]
	
USE Affiliate_N8B
GO

USE Affiliate_N8G
GO

*/

UPDATE c SET svalue = '2600.0000'
FROM dbo.SystemSettings c WITH (ROWLOCK, UPDLOCK) 
WHERE SName = 'Payment_MinAmount'
