/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250919@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Add more media codes from F101 to F500 [RedmineId : #236797]
        - Insert additional media codes (F101 to F500) into LandingPage_MediaCode table
        - Keep existing codes (F1 to F100) untouched
*/

 
USE Affiliate_12B;
GO

-- Generate additional media codes (F101 to F500)
;WITH Numbers AS (
    SELECT TOP 400 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 100 AS N  -- Start from 101
    FROM master.dbo.spt_values a
    CROSS JOIN master.dbo.spt_values b
    WHERE a.type = 'P' AND b.type = 'P'
)
INSERT INTO dbo.LandingPage_MediaCode (MediaCode, MediaId)
SELECT 
    'F' + RIGHT('000' + CAST(N AS VARCHAR(3)), 3) AS MediaCode,
    NULL AS MediaId
FROM Numbers
WHERE N BETWEEN 101 AND 500
ORDER BY N;