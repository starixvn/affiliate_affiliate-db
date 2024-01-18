/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231109@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new column TargetProductIds and initial data into column TargetProductIds [RedmineId : #181590]
*/

ALTER TABLE dbo.Banners
	ADD TargetProductIds VARCHAR(100) NOT NULL CONSTRAINT [DF_Banners_TargetProducts] DEFAULT ((''))
GO

/*
	--Initial data
*/
UPDATE b WITH (ROWLOCK, UPDLOCK) -- 158 rows
SET b.TargetProductIds = ISNULL(oap.TargetProductIds, '')
FROM dbo.Banners b
	OUTER APPLY(
		SELECT STRING_AGG(tp.TargetProductId, ',') AS TargetProductIds
		FROM (
			SELECT CASE WHEN value = 'Sportsbook' 	THEN 1 -- [Sports] in table TargetProduct
						WHEN value = 'Casino' 	  	THEN 5 -- [Casino] in table TargetProduct
						WHEN value = 'Number Game'	THEN 9 -- [Number Game] in table TargetProduct
				   END AS TargetProductId
			FROM STRING_SPLIT(b.Categories, ',')
		) AS tp
	) AS oap
GO

