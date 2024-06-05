/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240605@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data to recalculate commission [RedmineId : #180311]
*/

-- Backup data
SELECT *
INTO rptAffCommission_May2024
FROM rptAffCommission WITH (NOLOCK)
WHERE MonthDate = '2024-05-31'
GO

SELECT *
INTO rptAffDeduction_May2024
FROM rptAffDeduction WITH (NOLOCK)
WHERE MonthDate = '2024-05-31'
GO

SELECT *
INTO AffTrans_May2024
FROM AffTrans WITH (NOLOCK)
WHERE TransDate = '2024-05-31' AND TransType IN (201, 205)
GO

-- Delete data
DELETE rptAffCommission WITH (ROWLOCK, UPDLOCK) -- 2097 rows
WHERE MonthDate = '2024-05-31'
GO

DELETE rptAffDeduction WITH (ROWLOCK, UPDLOCK) -- 2531 rows
WHERE MonthDate = '2024-05-31'
GO

DELETE AffTrans WITH (ROWLOCK, UPDLOCK) -- 1788 rows
WHERE TransDate = '2024-05-31' AND TransType IN (201, 205)
GO