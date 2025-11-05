/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250808@Sally
    DB: DBAFF12B-Affiliate_12B
    Task: Migrate affiliate Marketing acccount [RedmineID: #235278]
*/
    USE Affiliate_12B
    GO

;WITH CTE_AffInfo AS (
    SELECT ai.AffId
    FROM dbo.AffInfo ai WITH (NOLOCK)
    WHERE ai.UserName IN (
        '12BETAFF16659'
    )
)

UPDATE ai WITH (ROWLOCK, UPDLOCK)
SET ai.AffCategoryId = 2
FROM dbo.AffInfo ai 
    INNER JOIN CTE_AffInfo tai ON ai.AffId = tai.AffId;


