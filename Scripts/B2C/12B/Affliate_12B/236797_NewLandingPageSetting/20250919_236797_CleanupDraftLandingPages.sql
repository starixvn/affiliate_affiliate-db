/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250919@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Clean up draft landing pages and all associated data [RedmineId : #236797]
        - Delete from LandingPage_Builder  
        - Delete associated records from LandingPage_BuilderDetail
        - Delete matching records from LandingPage table with same PageCode
        
    Note: This script will completely remove records from all three tables.
          Make sure you have a backup before running this cleanup.
*/

USE Affiliate_12B;
GO

-- Create temporary table to store affected records for logging
    CREATE TABLE #DeletedRecords (
        PageId INT,
        PageName VARCHAR(200),
        PageCode VARCHAR(100),
        DetailCount INT,
        LandingPageAffected BIT
    );

    -- Store records to be deleted for logging
    INSERT INTO #DeletedRecords (PageId, PageName, PageCode, DetailCount, LandingPageAffected)
    SELECT 
        b.PageId,
        b.PageName,
        b.PageCode,
        COUNT(DISTINCT bd.PageDetailId) AS DetailCount,
        CASE WHEN lp.PageCode IS NOT NULL THEN 1 ELSE 0 END AS LandingPageAffected
    FROM dbo.LandingPage_Builder b WITH (NOLOCK)
    LEFT JOIN dbo.LandingPage_BuilderDetail bd WITH (NOLOCK) ON b.PageId = bd.PageId
    LEFT JOIN dbo.LandingPage lp WITH (NOLOCK) ON b.PageCode = lp.PageCode   
    GROUP BY b.PageId, b.PageName, b.PageCode, lp.PageCode;

  
        -- 1. First clean up preview tables
        DELETE bdp
        FROM dbo.LandingPage_BuilderDetail_Preview bdp WITH (ROWLOCK, UPDLOCK);

        DELETE bp
        FROM dbo.LandingPage_Builder_Preview bp WITH (ROWLOCK, UPDLOCK);

        -- 2. Delete builder details for draft pages
        DELETE bd
        FROM dbo.LandingPage_BuilderDetail bd WITH (ROWLOCK, UPDLOCK)
        INNER JOIN dbo.LandingPage_Builder b WITH (NOLOCK) ON bd.PageId = b.PageId
   
        -- 3. Delete builder records
        DELETE b
        FROM dbo.LandingPage_Builder b WITH (ROWLOCK, UPDLOCK)
 
        -- 4. Delete associated landing pages
        DELETE lp
        FROM dbo.LandingPage lp WITH (ROWLOCK, UPDLOCK)
        INNER JOIN #DeletedRecords dr ON lp.PageCode = dr.PageCode;

        -- 5. Delete from LandingPage_Deal
        DELETE d
        FROM dbo.LandingPage_Deal d WITH (ROWLOCK, UPDLOCK);

        -- 6. Delete from LandingPage_Campaign
        DELETE c
        FROM dbo.LandingPage_Campaign c WITH (ROWLOCK, UPDLOCK);

        -- 7. Delete from LandingPage_MediaGallery where ModuleId is not 9
       /* DELETE mg
        FROM dbo.LandingPage_MediaGallery mg WITH (ROWLOCK, UPDLOCK)
        WHERE mg.ModuleId <> 9;   
        */   
    
    -- Cleanup
    DROP TABLE #DeletedRecords;
    PRINT 'Cleanup completed successfully';

GO