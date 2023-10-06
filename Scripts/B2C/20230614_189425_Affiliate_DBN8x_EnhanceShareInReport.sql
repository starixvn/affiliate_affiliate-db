/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20230614@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: 
		- Config CutOffDate  Report of Affiliate 		
*/  

INSERT INTO dbo.SystemSettings(
	SName, 
	SValue
)
SELECT t.SName
	,t.SValue
FROM (
	SELECT 'Report_CutOffDate' AS SName,'2023-06-01' AS SValue
)t
	LEFT JOIN SystemSettings s WITH (NOLOCK) ON s.SName = t.SName
WHERE s.SName IS NULL
GO

SELECT *
FROM dbo.SystemSettings s
WHERE SName ='Report_CutOffDate'

GO