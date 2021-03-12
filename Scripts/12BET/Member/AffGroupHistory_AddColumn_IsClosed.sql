/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210301@Percy
	DB: DBAFF12BET-Affiliate_12BET 
	Task: AffGroupHistory - Add new column IsClosed [RedminedId: #149213]

	Revisions:
		20210312@Percy: Initialize data for new column
*/
USE Affiliate_12BET
GO

--ALTER TABLE dbo.AffGroupHistory
--	ADD IsClosed BIT CONSTRAINT DF_AffGroupHistory_IsClosed DEFAULT ((0))
--GO

-- 4276 rows
UPDATE agh WITH (ROWLOCK)
SET agh.IsClosed = CASE
						WHEN agh.AffId NOT IN (92031807, 1243298) THEN 1
						WHEN agh.AffId = 92031807 AND agh.MonthDate >= '2020-07-31' THEN 1 -- 12BETAFF4735
						WHEN agh.AffId = 1243298  AND agh.MonthDate >= '2020-02-28' THEN 1 -- 12BETAFF036
						ELSE 0 END
FROM dbo.AffGroupHistory agh
	INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON agh.AffId = ai.AffId
WHERE agh.MonthDate >= '2020-01-31'
	AND ai.IsClosed = 1