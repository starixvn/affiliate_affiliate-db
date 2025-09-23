/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250918@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Add StatusId column to LandingPage table [RedmineId : #236797]
*/

USE Affiliate_12B;
GO

SET NOCOUNT ON;
GO

-- Add StatusId column to LandingPage table
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.LandingPage')
    AND name = 'StatusId'
)
BEGIN
    ALTER TABLE dbo.LandingPage
    ADD StatusId TINYINT NULL
    CONSTRAINT DF_LandingPage_StatusId DEFAULT 1;

    -- Update StatusId based on IsDeleted value
    UPDATE dbo.LandingPage WITH (ROWLOCK)
    SET StatusId = CASE 
                    WHEN IsDeleted = 0 THEN 1  -- Active
                    WHEN IsDeleted = 1 THEN 2  -- Inactive
                  END;
END
GO