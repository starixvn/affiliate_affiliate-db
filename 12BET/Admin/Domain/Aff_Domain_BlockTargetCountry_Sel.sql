/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Domain_BlockTargetCountry_Sel]
	@UserId			  	INT
	,@AffDomainId		INT = 0 
	,@12BetDomainId		INT = 0
AS
/*  
	Created: 20231102@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate/12Bet Domain and Domain Control - Block Target Country Popup

	Revisions:
		- 20231102@Eddie: Initialize SP [RedmineID: #181590]
		- 20240820@Eddie: Change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #209409]
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @UserId = ISNULL(@UserId, 0), @AffDomainId = ISNULL(@AffDomainId, 0), @12BetDomainId = ISNULL(@12BetDomainId, 0)
	
	CREATE TABLE #GridOfBlockTargetCountry
	(
		CountryCode VARCHAR(2)
	   ,CountryName	NVARCHAR(100)
	   ,Status		TINYINT	-- 0: Unselect, 1: Selected, 2: Disable
	)

	IF @UserId <> 0
	BEGIN
	
		INSERT INTO #GridOfBlockTargetCountry(CountryCode, CountryName, Status)
		SELECT DISTINCT tc.CountryCode, tc.CountryName, 0
		FROM dbo.UserMarket um WITH (NOLOCK)
			INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.MarketID = um.MarketId
		WHERE um.CustId = @UserId

		IF @AffDomainId <> 0 AND @12BetDomainId <> 0 --Admin >> Domain >> Domain Control:  Add New Domain Control Or Edit Domain Control
		BEGIN
			UPDATE gbtc
			SET gbtc.Status = 2
			FROM #GridOfBlockTargetCountry gbtc
				INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON gbtc.CountryCode NOT IN (SELECT value FROM STRING_SPLIT(b.BlockTargetCountry, ','))
				INNER JOIN dbo.[12BetDomain] c WITH (NOLOCK) ON gbtc.CountryCode NOT IN (SELECT value FROM STRING_SPLIT(c.BlockTargetCountry, ','))
			WHERE b.DomainId 	= @AffDomainId
				AND c.DomainId  = @12BetDomainId
				AND b.IsDeleted = 0
				AND c.IsDeleted = 0
			
			DELETE #GridOfBlockTargetCountry
			WHERE Status = 0
			
			UPDATE #GridOfBlockTargetCountry
			SET Status = 0
			WHERE Status = 2
			
		END
		ELSE IF @AffDomainId <> 0 --Admin >> Domain >> Affiliate Domain: Edit Affiliate Domain
		BEGIN
			;WITH CTE_adc AS
			(
				SELECT DISTINCT adc.TargetCountryCode
				FROM dbo.AffDomainControl adc WITH (NOLOCK) 
				WHERE adc.AffDomainID = @AffDomainId 
				  AND adc.IsDeleted = 0
			)
			UPDATE gbtc
			SET gbtc.Status = CASE WHEN n.TargetCountryCode IS NOT NULL THEN 2
								   WHEN ',' + ad.BlockTargetCountry + ',' LIKE '%,' + gbtc.CountryCode + ',%' THEN 1 
							       ELSE 0 END
			FROM #GridOfBlockTargetCountry gbtc
				LEFT JOIN dbo.AffDomain ad WITH (NOLOCK) ON ad.DomainID = @AffDomainId AND ad.IsDeleted = 0
				LEFT JOIN CTE_adc n ON n.TargetCountryCode = gbtc.CountryCode			
		END
		ELSE IF @12BetDomainId <> 0 --Admin >> Domain >> 12Bet Domain: Edit 12Bet Domain
		BEGIN
			;WITH CTE_adc AS
			(
				SELECT DISTINCT adc.TargetCountryCode
				FROM dbo.AffDomainControl adc WITH (NOLOCK) 
				WHERE adc.[12BetDomainID] = @12BetDomainId 
				  AND adc.IsDeleted = 0
			)
			UPDATE gbtc
			SET gbtc.Status = CASE WHEN n.TargetCountryCode IS NOT NULL THEN 2
								   WHEN ',' + ad.BlockTargetCountry + ',' LIKE '%,' + gbtc.CountryCode + ',%' THEN 1 
								   ELSE 0 END
			FROM #GridOfBlockTargetCountry gbtc
				LEFT JOIN dbo.[12BetDomain] ad WITH (NOLOCK) ON ad.DomainID = @12BetDomainId AND ad.IsDeleted = 0
				LEFT JOIN CTE_adc n ON n.TargetCountryCode = gbtc.CountryCode
		END
	END
	ELSE
	BEGIN
		INSERT INTO #GridOfBlockTargetCountry(CountryCode, CountryName, Status)
		SELECT DISTINCT CountryCode, CountryName, 0
		FROM dbo.TargetCountry WITH (NOLOCK)
	END
	
	SELECT CountryCode AS TargetCountryCode, CountryName AS TargetCountryName, Status
		,CASE CountryCode WHEN 'MY' THEN 1
						  WHEN 'BD' THEN 2
						  WHEN 'IN' THEN 3
						  WHEN 'ID' THEN 4
						  WHEN 'JP' THEN 5
						  WHEN 'KH' THEN 6
						  WHEN 'KR' THEN 7
						  WHEN 'TH' THEN 8
						  WHEN 'VN' THEN 9
						  WHEN 'CN' THEN 10
		END AS OrderID
	FROM #GridOfBlockTargetCountry
	ORDER BY OrderID ASC

	DROP TABLE #GridOfBlockTargetCountry
END
GO