/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210205@Malcolm
	DB: DBAFF12BET-Affiliate_12BET 
	Task: Add new permission [RedminedId : #149213]
*/
USE Affiliate_12BET
GO

ALTER TABLE dbo.MemberRemoval
	ADD MonthDate SMALLDATETIME,
		AffId INT
GO

-- 674 rows
UPDATE mr
SET mr.MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, mr.RemovedDate) + 1, 0)),
	mr.AffId = mi.AffId
FROM dbo.MemberRemoval mr WITH (ROWLOCK)
	INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mr.IBCCustId = mi.IBCCustId
GO

ALTER TABLE dbo.MemberRemoval
	ALTER COLUMN MonthDate SMALLDATETIME NOT NULL
GO

ALTER TABLE dbo.MemberRemoval
	DROP CONSTRAINT PK_MemberRemoval
GO

ALTER TABLE dbo.MemberRemoval
	ADD CONSTRAINT PK_MemberRemoval PRIMARY KEY CLUSTERED
	(
		IBCCustId ASC,
		MonthDate ASC
	) ON AccInfoData
GO