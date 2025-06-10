/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250521@Sally
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Migrate data P2P to DeductionSetting [RedmineID: #226985]

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/
-- Migrate data: All Product of P2P will be added to the first tier of each group
INSERT INTO dbo.DeductionSetting (
    GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent
)
SELECT 
    t.GroupId,
    10 AS DeductionId,
    t.ProductId,
    1 AS GroupProductId,
    t.DeductedPercentage,
    t.DeductedAmount,
    t.IsDeductedPercent
FROM (
     SELECT 
        TOP 1 WITH TIES t.GroupId,
        GroupProductId,
        g.ProductId,
        DeductedPercentage,
        DeductedAmount,
        IsDeductedPercent
    FROM dbo.DeductionSetting t WITH (NOLOCK)
		INNER JOIN (
			SELECT s.GroupId, s.ProductId
			FROM dbo.StraightSetting s WITH (NOLOCK)
                INNER JOIN dbo.Commgroup a WITH (NOLOCK) ON s.GroupId = a.GroupId AND a.Isdeleted = 0
			WHERE GroupProductId	= 1
		) g ON t.GroupId = g.GroupId
    WHERE t.DeductionId 	    = 10
		AND t.GroupProductId	= 1
	ORDER BY  ROW_NUMBER() OVER (PARTITION BY t.GroupId, g.ProductId ORDER BY t.GroupId DESC)   
) t
LEFT JOIN dbo.DeductionSetting d WITH (NOLOCK)
    ON d.GroupId 			= t.GroupId
    AND d.DeductionId 		= 10
    AND d.ProductId 		= t.ProductId
    AND d.GroupProductId 	= 1
WHERE d.GroupId IS NULL;
GO
DECLARE @MonthDate SMALLDATETIME = '2025-06-30';

INSERT INTO dbo.DeductionSettingHistory (
    GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent
)
SELECT 
    t.GroupId,
    @MonthDate AS MonthDate,
    10 AS DeductionId,
    t.ProductId,
    1 AS GroupProductId,
    t.DeductedPercentage,
    t.DeductedAmount,
    t.IsDeductedPercent
FROM (
   SELECT 
        TOP 1 WITH TIES t.GroupId,
        GroupProductId,
        g.ProductId,
        DeductedPercentage,
        DeductedAmount,
        IsDeductedPercent
    FROM dbo.DeductionSetting t WITH (NOLOCK)
		INNER JOIN (
			SELECT s.GroupId, s.ProductId
			FROM dbo.StraightSetting s WITH (NOLOCK)
                INNER JOIN dbo.Commgroup a WITH (NOLOCK) ON s.GroupId = a.GroupId AND a.Isdeleted = 0
			WHERE GroupProductId	= 1
		) g ON t.GroupId = g.GroupId
    WHERE t.DeductionId 	    = 10
		AND t.GroupProductId	= 1
	ORDER BY  ROW_NUMBER() OVER (PARTITION BY t.GroupId, g.ProductId ORDER BY t.GroupId DESC)  
) t
LEFT JOIN dbo.DeductionSettingHistory d WITH (NOLOCK) 
    ON d.GroupId 			= t.GroupId
    AND d.MonthDate 		= @MonthDate
    AND d.DeductionId 		= 10
    AND d.ProductId 		= t.ProductId
    AND d.GroupProductId 	= t.GroupProductId
WHERE d.GroupId IS NULL;
GO
UPDATE c SET SValue = '2025-06-01' FROM dbo.SystemSettings c WITH (ROWLOCK, UPDLOCK) WHERE  SName ='CommissionCal_CutOffDate'