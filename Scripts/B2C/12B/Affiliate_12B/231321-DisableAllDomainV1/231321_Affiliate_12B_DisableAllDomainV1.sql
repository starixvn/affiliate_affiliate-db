/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250624@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Disable all old domains of V1 & dont show them in Domain function [RedmineID: #231321]
*/

-- Step 1: (For reference only, not executable)
-- SELECT TOP 0 * FROM dbo.AffDomain WITH (NOLOCK)
-- SELECT TOP 0 * FROM dbo.DomainControl WITH (NOLOCK)

-- Step 2: Create Temp table
CREATE TABLE #ListAffDomainId (
    AffDomainId INT
);

-- Step 3: Insert data into #ListAffDomainId
INSERT INTO #ListAffDomainId (AffDomainId)
SELECT DomainId
FROM dbo.AffDomain WITH (NOLOCK)
WHERE DomainName LIKE '%go.%'
   OR DomainName LIKE '%12aff.%'
   OR DomainName LIKE '%partner.%'
   OR DomainName LIKE '%join.%';

-- Step 4: Update dbo.AffDomain
UPDATE d
SET d.IsDeleted = 1
FROM dbo.AffDomain d WITH (ROWLOCK, UPDLOCK)
	INNER JOIN #ListAffDomainId l ON d.DomainId = l.AffDomainId
WHERE d.IsDeleted = 0;

-- Step 5: Update dbo.DomainControl
UPDATE dc
SET dc.IsDeleted = 1
FROM dbo.DomainControl dc WITH (ROWLOCK, UPDLOCK)
	INNER JOIN #ListAffDomainId l ON dc.AffDomainId = l.AffDomainId
WHERE dc.IsDeleted = 0;
-- Drop temp table
DROP TABLE #ListAffDomainId;
