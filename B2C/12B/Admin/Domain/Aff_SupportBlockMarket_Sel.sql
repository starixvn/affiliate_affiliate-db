/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_SupportBlockMarket_Sel]
	@AffDomainId		INT = 0 
	,@LicenseeDomainId	INT = 0
AS
/*  
	Created: 20250312@Lewis
	DB: DBAFF12B.Affiliate_12B
	Task: Admin - Domain - AffiliateDomain/LicenseeDomain/DomainControl - Block Market Popup

	Revisions:
		- 20250312@Lewis: Initialize SP [RedmineID: #219496]
	Note: Order of English always is 1st
*/
BEGIN
	SET NOCOUNT ON

	--TODO: Get list markets
	CREATE TABLE #GridOfBlockMarket
	(
		MarketId 	NVARCHAR(10)
		,MarketName NVARCHAR(50)
		,Status		TINYINT	-- 0: Unselect, 1: Selected, 2: Disable
	)
	INSERT INTO #GridOfBlockMarket(MarketId, MarketName, Status)
	SELECT MarketId, MarketName, 0
	FROM dbo.Market WITH (NOLOCK)
	WHERE IsDeleted = 0

	--TODO: Domain Control
	IF @AffDomainId <> 0 AND @LicenseeDomainId <> 0 
	BEGIN
		UPDATE gbm
		SET gbm.Status = 2
		FROM #GridOfBlockMarket gbm
		WHERE 
			EXISTS (
				SELECT 1 
				FROM AffDomain b WITH (NOLOCK) 
				CROSS APPLY STRING_SPLIT(b.BlockMarket, ',') s
				WHERE b.DomainId = @AffDomainId 
					AND b.IsDeleted = 0 
					AND gbm.MarketId = s.value
			)
			OR EXISTS (
				SELECT 1 
				FROM LicenseeDomain c WITH (NOLOCK) 
				CROSS APPLY STRING_SPLIT(c.BlockMarket, ',') s
				WHERE c.DomainId = @LicenseeDomainId 
					AND c.IsDeleted = 0 
					AND gbm.MarketId = s.value
			);

		
		DELETE #GridOfBlockMarket
		WHERE Status = 2
		
		--UPDATE #GridOfBlockMarket
		--SET Status = 0
		--WHERE Status = 2
		
	END

	--TODO: Affiliate Domain
	IF @AffDomainId <> 0 AND @LicenseeDomainId = 0
	BEGIN
		WITH CTE_DC AS(
			SELECT DISTINCT MarketId 
			FROM DomainControl WITH (NOLOCK)
			WHERE AffDomainId = @AffDomainId AND IsDeleted = 0
		)
		, CTE_AD AS(
			SELECT DISTINCT s.value AS BlockMarketId
			FROM AffDomain a WITH (NOLOCK)
			CROSS APPLY STRING_SPLIT(a.BlockMarket, ',') s
			WHERE a.DomainId = @AffDomainId AND IsDeleted = 0
		)
		UPDATE bm
		SET bm.Status = 
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM CTE_DC WHERE MarketID = bm.MarketId
							) THEN 2
							WHEN EXISTS (
								SELECT 1 FROM CTE_AD WHERE BlockMarketID = bm.MarketId
							) THEN 1
							ELSE 0 
						END
		FROM #GridOfBlockMarket bm		
	END

	--TODO: Licensee Domain
	IF @LicenseeDomainId <> 0 AND @AffDomainId = 0
	BEGIN
		;WITH CTE_DC AS (
			SELECT MarketId 
			FROM DomainControl WITH (NOLOCK)
			WHERE LicenseeDomainId = @LicenseeDomainId AND IsDeleted = 0
		)
		,CTE_LD AS (
			SELECT s.value AS BlockMarketID
			FROM LicenseeDomain a WITH (NOLOCK) 
			CROSS APPLY STRING_SPLIT(a.BlockMarket, ',') s
			WHERE a.DomainId = @LicenseeDomainId AND a.IsDeleted = 0
		)
		UPDATE bm
		SET bm.Status = 
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM CTE_DC WHERE MarketID = bm.MarketId
							) THEN 2
							WHEN EXISTS (
								SELECT 1 FROM CTE_LD WHERE BlockMarketID = bm.MarketId
							) THEN 1
							ELSE 0 
						END
		FROM #GridOfBlockMarket bm;
	END
	
	-- TODO: Result
	SELECT MarketId, MarketName, Status,
		CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS TypeId
	FROM #GridOfBlockMarket
	ORDER BY TypeId, MarketId ASC
	
	DROP TABLE #GridOfBlockMarket
END
GO