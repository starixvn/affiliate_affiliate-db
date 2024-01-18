/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231025@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new column TargetCountryCode and initial data into column TargetCountryCode [RedmineId : #181590]
*/

ALTER TABLE dbo.AffDetail
	ADD TargetCountryCode VARCHAR(2) NOT NULL CONSTRAINT [DF_AffDetail_TargetCountryCode] DEFAULT ((''))
GO

/*
	--Initial data
*/
DROP TABLE IF EXISTS #TmpAffDetailUpd

DROP TABLE IF EXISTS #TmpAffDetailUpdTOP2000

CREATE TABLE #TmpAffDetailUpd (AffID INT PRIMARY KEY, PreferredLanguage VARCHAR(11))

CREATE TABLE #TmpAffDetailUpdTOP2000 (AffID INT PRIMARY KEY, PreferredLanguage VARCHAR(11))

INSERT INTO #TmpAffDetailUpd(AffID, PreferredLanguage)
SELECT AffID, PreferredLanguage
FROM dbo.AffDetail WITH (NOLOCK)



WHILE 1 = 1
BEGIN
	DELETE TOP(2000) FROM #TmpAffDetailUpd
	OUTPUT DELETED.AffID, DELETED.PreferredLanguage
	INTO #TmpAffDetailUpdTOP2000(AffID, PreferredLanguage)
	
	UPDATE ad WITH(ROWLOCK, UPDLOCK)
	SET ad.TargetCountryCode = ISNULL(tc.CountryCode, '')
	FROM dbo.AffDetail ad
		INNER JOIN #TmpAffDetailUpdTOP2000 u ON ad.AffID = u.AffID
		LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON ad.PreferredLanguage = tc.MarketID
	
	IF @@ROWCOUNT < 2000
		BREAK
		
	DELETE FROM #TmpAffDetailUpdTOP2000
	
	WAITFOR DELAY '00:00:00.280'
END

DROP TABLE #TmpAffDetailUpdTOP2000
DROP TABLE #TmpAffDetailUpd
GO