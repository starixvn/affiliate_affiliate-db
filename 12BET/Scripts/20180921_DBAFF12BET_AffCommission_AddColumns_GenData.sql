USE [Affiliate_12BET]
GO

/*
	Created: 20180921@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Gen data into new columns
*/

DECLARE @FromDate SMALLDATETIME = '2009-12-01', @ToDate SMALLDATETIME = '2018-08-31'

CREATE TABLE #AffData (WinlostDate SMALLDATETIME, AffId INT, SportId INT, MemberWithdrawal MONEY, ActivePlayer INT)

INSERT INTO #AffData (WinlostDate, AffId, SportId, MemberWithdrawal, ActivePlayer)
SELECT
	MonthDate,
	AffId,
	SportId,
	SUM(MemberWithdrawal),
	SUM(ActivePlayer)
FROM
(
	SELECT
		DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate, -- last day of month
		AffId,
		SportId,
		SUM(ISNULL(MemWithdrawal, 0)) AS MemberWithdrawal,
		0 AS ActivePlayer
	FROM dbo.AffDailySummary WITH (NOLOCK)
	WHERE WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY
		DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)), -- last day of month
		AffId,
		SportId

	UNION ALL
	SELECT
		MonthDate,
		AffId,
		Sporttype,
		0 AS MemberWithdrawal,
		COUNT(1) AS ActivePlayer
	FROM
	(
		SELECT
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)) AS MonthDate, -- last day of month
			md.IBCCustId,
			AffId,
			Sporttype
		FROM dbo.MemberDaily md WITH (NOLOCK)
			LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON md.IBCCustID = mr.IBCCustID
		WHERE WinlostDate BETWEEN @FromDate AND @ToDate
			AND (mr.IBCCustID IS NULL OR DATEDIFF(MONTH, mr.RemovedDate, md.WinlostDate) < 0)
		GROUP BY
			DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, WinlostDate) + 1, 0)),
			md.IBCCustId,
			AffId,
			Sporttype
		HAVING SUM(ISNULL(Turnover, 0)) > 0 OR SUM(ISNULL(Deposit, 0)) > 0
	) AS ac

	GROUP BY
		MonthDate,
		AffId,
		Sporttype
) AS r
GROUP BY
	MonthDate,
	AffId,
	SportId

SELECT DISTINCT WinlostDate FROM #AffData
ORDER BY WinlostDate

UPDATE ac WITH (ROWLOCK, UPDLOCK)
SET ac.MemberWithdrawal = ISNULL(ad.MemberWithdrawal, 0), ac.ActivePlayer = ISNULL(ad.ActivePlayer, 0)
FROM dbo.AffCommission ac
	LEFT JOIN #AffData ad ON ac.WinlostDate = ad.WinlostDate AND ac.AffID = ad.AffId AND ac.SportID = ad.SportId
WHERE ac.WinlostDate BETWEEN '2009-12-31' AND '2012-12-31'

UPDATE ac WITH (ROWLOCK, UPDLOCK)
SET ac.MemberWithdrawal = ISNULL(ad.MemberWithdrawal, 0), ac.ActivePlayer = ISNULL(ad.ActivePlayer, 0)
FROM dbo.AffCommission ac
	LEFT JOIN #AffData ad ON ac.WinlostDate = ad.WinlostDate AND ac.AffID = ad.AffId AND ac.SportID = ad.SportId
WHERE ac.WinlostDate BETWEEN '2013-01-31' AND '2015-12-31'

UPDATE ac WITH (ROWLOCK, UPDLOCK)
SET ac.MemberWithdrawal = ISNULL(ad.MemberWithdrawal, 0), ac.ActivePlayer = ISNULL(ad.ActivePlayer, 0)
FROM dbo.AffCommission ac
	LEFT JOIN #AffData ad ON ac.WinlostDate = ad.WinlostDate AND ac.AffID = ad.AffId AND ac.SportID = ad.SportId
WHERE ac.WinlostDate BETWEEN '2016-01-31' AND '2018-08-31'

DROP TABLE #AffData