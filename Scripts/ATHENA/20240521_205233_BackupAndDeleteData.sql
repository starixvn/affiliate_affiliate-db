/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Created: 20240521@Eddie
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Task: Backup and Delete Data [Redmine: #205233]
*/

-- Backup
SELECT *
INTO MemberDaily_April2024
FROM MemberDaily WITH (NOLOCK)
WHERE WinlostDate >= '2024-04-01' AND WinlostDate < '2024-05-01'
GO

SELECT *
INTO AffDaily_April2024
FROM AffDaily WITH (NOLOCK)
WHERE WinlostDate >= '2024-04-01' AND WinlostDate < '2024-05-01'
GO

SELECT *
INTO AffDailySummary_April2024
FROM AffDailySummary WITH (NOLOCK)
WHERE WinlostDate >= '2024-04-01' AND WinlostDate < '2024-05-01'
GO


SELECT *
INTO AffTrans_April2024
FROM AffTrans WITH (NOLOCK)
GO

SELECT *
INTO AffCommission_April2024
FROM AffCommission WITH (NOLOCK)
GO

-- Delete

DELETE ac WITH (ROWLOCK, UPDLOCK)
FROM AffCommission ac
WHERE ac.WinlostDate = '2024-04-30'
GO

DELETE t WITH (ROWLOCK, UPDLOCK)
FROM AffTrans t
WHERE t.TransDate  = '2024-04-30' AND t.TransType = 201
GO

-- only Macaubet
	DELETE t WITH (ROWLOCK, UPDLOCK)
	FROM AffTrans t
	WHERE t.TransID IN (103003, 103004) AND t.TransType = 203
	GO
	
	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET BF = dbo.Aff_GetAffBalance (AffID)  
	WHERE AffID = 10855
	GO
--