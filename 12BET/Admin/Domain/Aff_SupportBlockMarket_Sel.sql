/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_SupportBlockMarket_Sel]
	@UserId			  	INT
	,@AffDomainId		INT = 0 
	,@12BetDomainId		INT = 0
AS
/*  
	Created: 20221103@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate/12Bet Domain and Domain Control - Block Market Popup

	Revisions:
		- 20221114@Eddie: Initialize SP [RedmineID: #179537]
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @UserId = ISNULL(@UserId, 0), @AffDomainId = ISNULL(@AffDomainId, 0), @12BetDomainId = ISNULL(@12BetDomainId, 0)
	
	CREATE TABLE #GridOfBlockMarket
	(
		MarketId 	NVARCHAR(10)
		,MarketName NVARCHAR(50)
		,Status		TINYINT	-- 0: Unselect, 1: Selected, 2: Disable
	)
	IF @UserId <> 0
	BEGIN
	
		INSERT INTO #GridOfBlockMarket(MarketId, MarketName, Status)
		SELECT m.MarketID, m.MarketName, 0
		FROM dbo.UserMarket um WITH (NOLOCK)
			INNER JOIN dbo.Market m WITH (NOLOCK) ON m.MarketID = um.MarketId
		WHERE um.CustId = @UserId

		IF @AffDomainId <> 0 AND @12BetDomainId <> 0 --Admin >> Domain >> Domain Control:  Add New Domain Control Or Edit Domain Control
		BEGIN
			UPDATE gbm
			SET gbm.Status = 2
			FROM #GridOfBlockMarket gbm
				INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON gbm.MarketId NOT IN (SELECT value FROM STRING_SPLIT(b.BlockMarket, ','))
				INNER JOIN dbo.[12BetDomain] c WITH (NOLOCK) ON gbm.MarketId NOT IN (SELECT value FROM STRING_SPLIT(c.BlockMarket, ','))
			WHERE b.DomainId = @AffDomainId
				AND c.DomainId = @12BetDomainId
				AND b.IsDeleted = 0
				AND c.IsDeleted = 0
			
			DELETE #GridOfBlockMarket
			WHERE Status = 0
			
			UPDATE #GridOfBlockMarket
			SET Status = 0
			WHERE Status = 2
			
		END
		ELSE IF @AffDomainId <> 0 --Admin >> Domain >> Affiliate Domain: Edit Affiliate Domain
		BEGIN
			;WITH CTE_adc AS
			(
				SELECT DISTINCT adc.MarketID
				FROM dbo.AffDomainControl adc WITH (NOLOCK) 
				WHERE adc.AffDomainID = @AffDomainId 
					AND adc.IsDeleted = 0
			)
			UPDATE bm
			SET bm.Status = CASE WHEN n.MarketID IS NOT NULL THEN 2
								 WHEN ',' + ad.BlockMarket + ',' LIKE '%,' + bm.MarketId + ',%' THEN 1 
								 ELSE 0 END
			FROM #GridOfBlockMarket bm
				LEFT JOIN dbo.AffDomain ad WITH (NOLOCK) ON ad.DomainID = @AffDomainId AND ad.IsDeleted = 0
				LEFT JOIN CTE_adc n ON n.MarketID = bm.MarketId			
		END
		ELSE IF @12BetDomainId <> 0 --Admin >> Domain >> 12Bet Domain: Edit 12Bet Domain
		BEGIN
			;WITH CTE_adc AS
			(
				SELECT DISTINCT adc.MarketID
				FROM dbo.AffDomainControl adc WITH (NOLOCK) 
				WHERE adc.[12BetDomainID] = @12BetDomainId 
					AND adc.IsDeleted = 0
			)
			UPDATE bm
			SET bm.Status = CASE WHEN n.MarketID IS NOT NULL THEN 2
								 WHEN ',' + ad.BlockMarket + ',' LIKE '%,' + bm.MarketId + ',%' THEN 1 
								 ELSE 0 END
			FROM #GridOfBlockMarket bm
				LEFT JOIN dbo.[12BetDomain] ad WITH (NOLOCK) ON ad.DomainID = @12BetDomainId AND ad.IsDeleted = 0
				LEFT JOIN CTE_adc n ON n.MarketID = bm.MarketId
		END
	END
	ELSE
	BEGIN
		INSERT INTO #GridOfBlockMarket(MarketId, MarketName, Status)
		SELECT MarketId, MarketName, 0
		FROM dbo.Market WITH (NOLOCK)
	END
	
	SELECT MarketId, MarketName, Status
	FROM #GridOfBlockMarket
	ORDER BY MarketId ASC
	
	DROP TABLE #GridOfBlockMarket
END
GO