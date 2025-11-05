/*<info serverAlias="DBAFF12B-Affiliate_12B,DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
    Created: 20250425@Sally
    DB: DBAFF12B-Affiliate_12B,DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
    Task: OneClick Implementation [RedmineID: #227824]

    USE Affiliate_12B
    GO

    USE Affiliate_N88
    GO

    USE Affiliate_N8B
    GO

    USE Affiliate_N8G
    GO
*/

-- Add a new column 'AffCategoryId' to the 'AffInfo' table
ALTER TABLE dbo.AffInfo
ADD AffCategoryId TINYINT NULL;
GO
-- Update the 'AffCategoryId' column to 1 for all existing records in the 'AffInfo' table in batches of 2000
WHILE 1 = 1
BEGIN
    UPDATE TOP (2000) dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
    SET AffCategoryId = 1
    WHERE AffCategoryId IS NULL;

    IF @@ROWCOUNT = 0
        BREAK;
END
GO

-- Add a default constraint 'DF_Affinfo_AffCategoryId' with a default value of 1
IF NOT EXISTS (
    SELECT TOP 1 1
    FROM dbo.AffInfo WITH (NOLOCK)
    WHERE AffCategoryId IS NULL
)
BEGIN
    ALTER TABLE dbo.AffInfo
    ADD CONSTRAINT DF_Affinfo_AffCategoryId DEFAULT 1 FOR AffCategoryId
END;
GO
CREATE TABLE dbo.AffCategory
(
    AffCategoryId TINYINT NOT NULL,
    AffCategoryName NVARCHAR(50) NOT NULL,
    AffCategoryDesc NVARCHAR(255) NULL,
    CONSTRAINT PK_AffCategory PRIMARY KEY (AffCategoryId)
);
GO
-- Insert default values into the 'AffCategory' table
INSERT INTO dbo.AffCategory (AffCategoryId, AffCategoryName, AffCategoryDesc)
SELECT t.AffCategoryId, t.AffCategoryName, t.AffCategoryDesc
FROM (VALUES
    (1, 'Affiliate', 'Normal Affiliate Account'),
    (2, 'Marketing', 'Marketing Affiliate Account')
) AS t(AffCategoryId, AffCategoryName, AffCategoryDesc)
    LEFT JOIN dbo.AffCategory  ac ON t.AffCategoryId = ac.AffCategoryId
WHERE ac.AffCategoryId IS NULL;
GO