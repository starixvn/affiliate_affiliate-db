/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250729@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Delete specific domain control [RedmineID: #233219]
*/
USE Affiliate_12B
GO

BEGIN

	DROP TABLE IF EXISTS #DomainControl_tmp
	DROP TABLE IF EXISTS #SpecificDomainControl_NoDel

	CREATE TABLE #DomainControl_tmp
	(
		Id INT
		,AffDomain NVARCHAR(50)
		,LicenseeDomain NVARCHAR(50)
		,TargetCountryCode VARCHAR(5)
		,ShortedCode VARCHAR(20)
	)
	
	CREATE TABLE #SpecificDomainControl_NoDel
	(
		AffId  INT
		,AffDomain NVARCHAR(100)
	)

	-- Exist in DomainControl
	; WITH CTE_Check AS (
		SELECT CountryCode, ShortedCode 
		FROM TargetCountry WITH (NOLOCK)
		WHERE OrderNo IS NOT NULL
	)
	INSERT INTO #DomainControl_tmp(Id, AffDomain, LicenseeDomain, TargetCountryCode, ShortedCode)
	SELECT dc.Id, ad.DomainName AS AffDomain, ld.DomainName AS LicenseeDomain, dc.TargetCountryCode, c.ShortedCode
	FROM DomainControl dc WITH (NOLOCK)
		INNER JOIN AffDomain ad WITH (NOLOCK) ON ad.DomainId = dc.AffDomainId
		INNER JOIN LicenseeDomain ld WITH (NOLOCK) ON ld.DomainId = dc.LicenseeDomainId
		INNER JOIN CTE_Check c ON c.CountryCode = dc.TargetCountryCode
	WHERE ( ad.DomainName LIKE '%goto.oli368.com%' OR ad.DomainName LIKE '%goto.5689fun.com%' OR ad.DomainName LIKE '%goto.168sure.com%')
	  AND dc.status = 1
	  AND ad.IsDeleted = 0
	  AND dc.IsDeleted = 0
	  AND NOT EXISTS ( SELECT 1 
					   FROM DomainControl ddc WITH (NOLOCK)
					   WHERE (ddc.Id = dc.Id) AND ( (AffDomainId = 255 AND LicenseeDomainId = 280)  -- new data in script 1
                                                 OR (AffDomainId = 256 AND LicenseeDomainId = 283)  -- new data in script 1
                                                 OR (AffDomainId = 267 AND LicenseeDomainId = 251)) -- new data in script 1
				    )

	-- No deletion in SpecificDomainControl
	;WITH CTE_AffCheck AS (
		SELECT AffId, AffMediaLink, LanguageCode, COUNT(1) AS num
		FROM ClickStatistics_bk WITH (NOLOCK)
		WHERE AffMediaLink LIKE '%goto.oli368.com%' OR AffMediaLink LIKE '%goto.5689fun.com%' OR AffMediaLink LIKE '%goto.168sure.com%'
		GROUP BY AffId, AffMediaLink, LanguageCode
    
		UNION ALL
    
		SELECT AffId, AffMediaLink, LanguageCode, COUNT(1) AS num
		FROM ClickStatistics WITH (NOLOCK)
		WHERE AffMediaLink LIKE '%goto.oli368.com%' OR AffMediaLink LIKE '%goto.5689fun.com%' OR AffMediaLink LIKE '%goto.168sure.com%'
		GROUP BY AffId, AffMediaLink, LanguageCode
	)
	INSERT INTO #SpecificDomainControl_NoDel(AffId, AffDomain)
	SELECT a.AffId, dct.AffDomain
	FROM AffInfo a WITH (NOLOCK)
		INNER JOIN CommGroup c WITH (NOLOCK) ON c.GroupId = a.GroupId
		INNER JOIN CTE_AffCheck ca ON ca.AffId = a.AffId
		INNER JOIN #DomainControl_tmp dct ON dct.ShortedCode = ca.LanguageCode
										 AND ca.AffMediaLink LIKE '%' + dct.AffDomain + '%'
	WHERE c.GroupName = 'NoCommission-CPA'

	SELECT *
	INTO DEL_SpecificDomainControl
	FROM dbo.SpecificDomainControl sdc WITH (NOLOCK)
	WHERE sdc.AffDomainName IN ('goto.5689fun.com', 'goto.168sure.com', 'goto.oli368.com')
	  AND NOT EXISTS ( SELECT 1 FROM #SpecificDomainControl_NoDel sn WHERE sn.AffId = sdc.AffId 
																	   AND sn.AffDomain = sdc.AffDomainName)

	DELETE sdc
	FROM dbo.SpecificDomainControl sdc
	WHERE sdc.AffDomainName IN ('goto.5689fun.com', 'goto.168sure.com', 'goto.oli368.com')
	  AND NOT EXISTS ( SELECT 1 FROM #SpecificDomainControl_NoDel sn WHERE sn.AffId = sdc.AffId 
																	   AND sn.AffDomain = sdc.AffDomainName)

	DROP TABLE #DomainControl_tmp
	DROP TABLE #SpecificDomainControl_NoDel
END
GO