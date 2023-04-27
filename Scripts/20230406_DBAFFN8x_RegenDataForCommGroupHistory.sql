/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20230406@Malcolm 
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Regen data for CommGroupHistory [RedminId : # 185481]
*/

/*
USE Affiliate_N88
GO

USE Affiliate_N8B
GO

USE Affiliate_N8G
GO
*/

DECLARE @MinDate DATETIME = '2020-05-01', @MaxDate DATETIME = '2023-04-01' -- Current month

;WITH CTE_MonthDate AS
(
	SELECT @MinDate AS MonthDate
	UNION ALL
	SELECT DATEADD(MONTH, 1, MonthDate)
	FROM CTE_MonthDate
	WHERE MonthDate <= @MaxDate
)
INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate)
SELECT cg.GroupId, DATEADD(DAY, -1, e.MonthDate) AS MonthDate, 0.1 AS SubCommRate
FROM dbo.CommGroup cg WITH(NOLOCK)
	CROSS JOIN CTE_MonthDate e
	
UPDATE CommGroup WITH(ROWLOCK, UPDLOCK)
	SET SubCommRate = 0.1
WHERE SubCommRate IS NULL




