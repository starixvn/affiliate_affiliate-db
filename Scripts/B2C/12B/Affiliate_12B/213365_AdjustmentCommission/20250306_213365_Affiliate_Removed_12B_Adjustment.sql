/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250306@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Adjustment BBF- Commission Feb 2025 [RedmineID: #212201]
        - Remove Adjustment
*/
USE Affiliate_12B;
GO
SELECT COUNT(1) -- 86 rows
FROM dbo.AffTrans c  WITH(NOLOCK)	
WHERE c.TransType =  '203' 
	AND c.Description in ( 'Adjustment - Commission of Feb.2025','Adjustment - Promotion boost')
	AND c.Creator = 1000000000
	AND c.TransDate >='20250305'

DELETE c 
FROM dbo.AffTrans c  WITH(UPDLOCK, ROWLOCK)	
WHERE c.TransType =  '203' 
	AND c.Description in ( 'Adjustment - Commission of Feb.2025','Adjustment - Promotion boost')
	AND c.Creator = 1000000000
	AND c.TransDate >='20250305'


