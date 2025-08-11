/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sally
    DB: DBAFF12B-Affiliate_12B
    Task: Sync GroupId from AffGroupHistory to AffInfo for migrated affiliates [RedmineID: #234153]

    USE Affiliate_12B
    GO
*/

-- CTE: Get all AffInfo (AffCategoryId = 2, Status = 'Approved') joined with AffGroupHistory (MonthDate = '2025-07-31', GroupId = 34)
;WITH MigratedAffiliates AS (
    SELECT agh.AffId, agh.GroupId AS NewGroupId, ai.GroupId AS OldGroupId
    FROM dbo.AffGroupHistory agh WITH (NOLOCK)
    INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON agh.AffId = ai.AffId
    WHERE ai.AffCategoryId = 2
      AND ai.Status = 'Approved'
      AND agh.MonthDate = '2025-07-31'
      AND agh.GroupId = 34
      AND ISNULL(ai.GroupId, -1) <> agh.GroupId
)
UPDATE ai
SET ai.GroupId = ma.NewGroupId
FROM dbo.AffInfo ai WITH(ROWLOCK, UPDLOCK)
INNER JOIN MigratedAffiliates ma ON ai.AffId = ma.AffId;

-- Verify the update
SELECT COUNT(1) AS UpdatedCount
FROM dbo.AffInfo ai WITH (NOLOCK)
INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON ai.AffId = agh.AffId
WHERE ai.AffCategoryId = 2
  AND ai.Status = 'Approved'
  AND agh.MonthDate = '2025-07-31'
  AND agh.GroupId = 34
  AND ai.GroupId = agh.GroupId;
