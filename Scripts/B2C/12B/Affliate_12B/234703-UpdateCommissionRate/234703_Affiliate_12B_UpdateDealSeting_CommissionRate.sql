/*<info serverAlias="DBAFF12B-Affiliate_12B" ></info>*/
/*  
	Created: 20251104@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Update Setting CommissionRate For 50% Fix Commission -  NNCO Deal [RedmineId: #234703]

*/
USE Affiliate_12B
GO
-- 1 row affected
UPDATE c
SET Commission = 0.50000000
FROM dbo.TierSettingHistory  c WITH (ROWLOCK, UPDLOCK) 
WHERE GroupId = 61 AND MonthDate = '2025-10-31' AND TierId = 2 AND GroupProductId = 10 