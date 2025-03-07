/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250305@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Adjustment BBF- Commission Feb 2025 [RedmineID: #212201]
       
*/
USE Affiliate_12B;
GO

UPDATE a SET a.SValue ='2025-02-28'
FROM dbo.SystemSettings a WITH (ROWLOCK,UPDLOCK) 
WHERE SName = 'AFF_CommissionDate'
GO			