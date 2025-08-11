/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sally
    DB: DBAFF12B-Affiliate_12B
    Task: Sync GroupId from AffGroupHistory to AffInfo for migrated affiliates [RedmineID: #234153]

    USE Affiliate_12B
    GO
*/

-- Declare variables
DECLARE @MonthDate DATETIME = '2025-08-31';

-- Create temporary table to store affiliate information
CREATE TABLE #tempAffiliateInfo (
    Username NVARCHAR(30) NOT NULL,
    AffId INT NULL
);

-- Insert affiliate usernames
INSERT INTO #tempAffiliateInfo (Username)
VALUES 
    ('12BETAFF16473'),
    ('12BETAFF16342'),
    ('12BETAFF16477'),
    ('12BETAFF16454'),
    ('12BETAFF16455'),
    ('12BETAFF16456'),
    ('12BETAFF16457'),
    ('12BETAFF16480'),
    ('12BETAFF16481'),
    ('12BETAFF16482'),
    ('12BETAFF16483'),
    ('12BETAFF16496'),
    ('12BETAFF16007'),
    ('12BETAFF16476'),
    ('12BETAFF16472'),
    ('12BETAFF15238'),
    ('12BETAFF15829'),
    ('12BETAFF16485'),
    ('12BETAFF16486'),
    ('12BETAFF16343'),
    ('12BETAFF16344'),
    ('12BETAFF6462'),
    ('12BETAFF16105'),
    ('12BETAFF16547'),
    ('12BETAFF16449'),
    ('12BETAFF16377'),
    ('12BETAFF16094'),
    ('12BETAFF15426'),
    ('12BETAFF16019'),
    ('12BETAFF15668'),
    ('12BETAFF16646'),
    ('12BETAFF16083'),
    ('12BETAFF16479'),
    ('12BETAFF16478');

-- Get AffId for each username
UPDATE tai WITH (ROWLOCK, UPDLOCK)
SET AffId = ai.AffId
FROM #tempAffiliateInfo tai
INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON tai.Username = ai.UserName;

-- Update AffInfo table for those affiliates
UPDATE ai WITH (ROWLOCK, UPDLOCK)
SET Email = '12arpitasingh12@gmail.com',
    AffCategoryId = 2,
    GroupId = CASE 
        WHEN ai.Status = 'Approved' THEN 34
        ELSE ai.GroupId 
    END
FROM dbo.AffInfo ai
INNER JOIN #tempAffiliateInfo tai ON ai.AffId = tai.AffId
WHERE tai.AffId IS NOT NULL;

-- Update AffGroupHistory table for those affiliates where GroupId differs
UPDATE agh WITH (ROWLOCK, UPDLOCK)
SET GroupId = ai.GroupId
FROM dbo.AffGroupHistory agh
INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON agh.AffId = ai.AffId
INNER JOIN #tempAffiliateInfo tai ON ai.AffId = tai.AffId
WHERE agh.MonthDate = @MonthDate
    AND ISNULL(ai.GroupId, -1) <> agh.GroupId
    AND tai.AffId IS NOT NULL;

-- Verification queries
SELECT 'AffInfo Updates' AS TableName, COUNT(1) AS UpdatedCount
FROM dbo.AffInfo ai WITH (NOLOCK)
INNER JOIN #tempAffiliateInfo tai ON ai.AffId = tai.AffId
WHERE ai.Email = '12arpitasingh12@gmail.com'
    AND ai.AffCategoryId = 2
    AND tai.AffId IS NOT NULL;

SELECT 'AffGroupHistory Updates' AS TableName, COUNT(1) AS UpdatedCount
FROM dbo.AffGroupHistory agh WITH (NOLOCK)
INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON agh.AffId = ai.AffId
INNER JOIN #tempAffiliateInfo tai ON ai.AffId = tai.AffId
WHERE ai.AffCategoryId = 2
    AND ai.Status = 'Approved'
    AND agh.MonthDate = @MonthDate
    AND ai.GroupId = agh.GroupId
    AND tai.AffId IS NOT NULL;

-- Clean up temporary table
DROP TABLE #tempAffiliateInfo;
