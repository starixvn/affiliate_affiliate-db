/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Domain_BlockTargetCountry_Sel]
	@AffDomainId		INT = 0 
	,@LicenseeDomainId	INT = 0
AS
/*  
	Created: 20250418@Lewis
	DB: DBAFF12B.Affiliate_12B
	Task: Admin - Domain - AffiliateDomain/LicenseeDomain/DomainControl - Block TargetCountry Popup

	Revisions:
		- 20250417@Lewis: Initialize SP [RedmineID: #223644]
*/
BEGIN
	SET NOCOUNT ON

	--TODO: Get list TargetCountry
	CREATE TABLE #GridOfBlockTargetCountry
	(
		CountryCode VARCHAR(5)
	   ,CountryName	NVARCHAR(100)
	   ,Status		TINYINT	-- 0: Unselect, 1: Selected
	   ,IsUsedDomainControl BIT DEFAULT(0)
	)
	INSERT INTO #GridOfBlockTargetCountry(CountryCode, CountryName, Status)
	SELECT DISTINCT CountryCode, CountryName, 0
	FROM dbo.TargetCountry tc WITH (NOLOCK)
	INNER JOIN Market m WITH (NOLOCK) ON m.MarketId = tc.MarketID AND m.IsDeleted = 0

	--TODO: Domain Control
	IF @AffDomainId <> 0 AND @LicenseeDomainId <> 0 
	BEGIN
		UPDATE gbm
		SET gbm.Status = 2
		FROM #GridOfBlockTargetCountry gbm
		WHERE 
			EXISTS (
				SELECT 1 
				FROM AffDomain b WITH (NOLOCK) 
				CROSS APPLY STRING_SPLIT(b.BlockTargetCountry, ',') s
				WHERE b.DomainId = @AffDomainId 
					AND b.IsDeleted = 0 
					AND gbm.CountryCode = s.value
			)
			OR EXISTS (
				SELECT 1 
				FROM LicenseeDomain c WITH (NOLOCK) 
				CROSS APPLY STRING_SPLIT(c.BlockTargetCountry, ',') s
				WHERE c.DomainId = @LicenseeDomainId 
					AND c.IsDeleted = 0 
					AND gbm.CountryCode = s.value
			);

		
		DELETE #GridOfBlockTargetCountry
		WHERE Status = 2 
		
	END

	--TODO: Affiliate Domain
	IF @AffDomainId <> 0 AND @LicenseeDomainId = 0
	BEGIN
		WITH CTE_DC AS(
			SELECT DISTINCT TargetCountryCode 
			FROM DomainControl WITH (NOLOCK)
			WHERE AffDomainId = @AffDomainId AND IsDeleted = 0
		)
		, CTE_AD AS(
			SELECT DISTINCT s.value AS BlockTargetCountryCode
			FROM AffDomain a WITH (NOLOCK)
			CROSS APPLY STRING_SPLIT(a.BlockTargetCountry, ',') s
			WHERE a.DomainId = @AffDomainId AND IsDeleted = 0
		)
		UPDATE bm
		SET bm.Status = 
						CASE 
							WHEN EXISTS (SELECT 1 FROM CTE_AD WHERE BlockTargetCountryCode = bm.CountryCode) THEN 1
							ELSE 0 
						END
			,bm.IsUsedDomainControl = 
						CASE 
							WHEN EXISTS (SELECT 1 FROM CTE_DC WHERE TargetCountryCode = bm.CountryCode) THEN 1
							ELSE 0 
						END
		FROM #GridOfBlockTargetCountry bm		
	END

	--TODO: Licensee Domain
	IF @LicenseeDomainId <> 0 AND @AffDomainId = 0
	BEGIN
		;WITH CTE_DC AS (
			SELECT DISTINCT TargetCountryCode  
			FROM DomainControl WITH (NOLOCK)
			WHERE LicenseeDomainId = @LicenseeDomainId AND IsDeleted = 0
		)
		,CTE_LD AS (
			SELECT DISTINCT s.value AS BlockTargetCountryCode
			FROM LicenseeDomain a WITH (NOLOCK) 
			CROSS APPLY STRING_SPLIT(a.BlockTargetCountry, ',') s
			WHERE a.DomainId = @LicenseeDomainId AND a.IsDeleted = 0
		)
		UPDATE bm
		SET bm.Status = 
						CASE 
							WHEN EXISTS (SELECT 1 FROM CTE_LD WHERE BlockTargetCountryCode = bm.CountryCode) THEN 1
							ELSE 0 
						END
			,bm.IsUsedDomainControl = 
						CASE 
							WHEN EXISTS (SELECT 1 FROM CTE_DC WHERE TargetCountryCode = bm.CountryCode) THEN 1
							ELSE 0 
						END
		FROM #GridOfBlockTargetCountry bm;
	END
	
	-- TODO: Result
	SELECT 
			g.CountryCode AS TargetCountryCode
			, g.CountryName AS TargetCountryName
			, g.Status
			, g.IsUsedDomainControl
			, tc.OrderNo
	FROM #GridOfBlockTargetCountry g
	INNER JOIN TargetCountry tc WITH (NOLOCK) ON g.CountryCode = tc.CountryCode
	WHERE tc.OrderNo IS NOT NULL
	ORDER BY OrderNo
	
	DROP TABLE #GridOfBlockTargetCountry
END
GO