/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250912@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: New Landing Page Setting - Insert MediaCode Data [RedmineId : #236797]
        - Insert initial data into LandingPage_MediaCode table
*/

use Affiliate_12B
GO
-- Insert data into LandingPage_MediaCode
TRUNCATE TABLE dbo.LandingPage_MediaCode;

-- Generate 100 media codes (F1 to F100)
;WITH Numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM master.dbo.spt_values 
    WHERE type = 'P' AND number < 100
)
INSERT INTO dbo.LandingPage_MediaCode (MediaCode, MediaId)
SELECT 
    'F' + CAST(N AS VARCHAR(3)) AS MediaCode,
    NULL AS MediaId  -- MediaId will need to be updated when media is assigned
FROM Numbers
WHERE N <= 100;
GO
