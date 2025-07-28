/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sally
    DB: DBAFF12B-Affiliate_12B
    Task: Migrate AffiliateInfo [RedmineID: #227824]

    USE Affiliate_12B
    GO

*/

-- Update AffCategoryId for records with specific email
-- Current records found with Email = '12arpitasingh12@gmail.com' and AffCategoryId = 1:
-- AffId: 1535293, 92037254, 92043586, 92043593, 92043594

UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
SET AffCategoryId = 2  -- Changing from 1 to 2
WHERE Email = '12arpitasingh12@gmail.com' 
    AND AffCategoryId = 1;

-- Verify the update
SELECT COUNT(1) AS UpdatedCount
FROM dbo.AffInfo WITH(NOLOCK)
WHERE Email = '12arpitasingh12@gmail.com';
GO
-- ============================================
-- Update GroupId for Approved Affiliates (AffCategoryId = 1)
-- Only for records in AffGroupHistory with MonthDate = '2025-07-31'
-- ============================================

;WITH ApprovedAffiliates AS (
    SELECT AffId
    FROM dbo.AffInfo WITH (NOLOCK)
    WHERE AffCategoryId = 2
        AND Status = 'Approved'
)
UPDATE agh WITH (ROWLOCK, UPDLOCK)
SET GroupId = 34
FROM dbo.AffGroupHistory agh 
    INNER JOIN ApprovedAffiliates aa ON agh.AffId = aa.AffId
WHERE agh.MonthDate = '2025-07-31'
AND agh.GroupId <> 4;  -- Ensure we only update if GroupId is not already 4

-- Kiểm tra số lượng bản ghi đã cập nhật
SELECT COUNT(1) AS UpdatedCount
FROM dbo.AffGroupHistory WITH (NOLOCK)
WHERE MonthDate = '2025-07-31'
    AND GroupId = 34
    AND AffId IN (
        SELECT AffId FROM dbo.AffInfo WITH (NOLOCK)
        WHERE AffCategoryId = 2 AND Status = 'Approved'
    );
