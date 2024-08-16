/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_ExcludedTargetCountry_Sel]
	@UserId	 INT
	,@PageId SMALLINT = 0
AS
/*  
	Created: 20231107@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Landing Page List - Excluded Target Country Popup

	Revisions:
		- 20231107@Eddie: Initialize SP [RedmineID: #181590]
		- 20240820@Eddie: Change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #209409]
*/
BEGIN
	SET NOCOUNT ON

	SELECT @UserId = ISNULL(@UserId, 0), @PageId = ISNULL(@PageId, 0)

	CREATE TABLE #GridOfExcludedTargetCountry
	(
		CountryCode VARCHAR(2)
	   ,CountryName	NVARCHAR(100)
	   ,Status		TINYINT	-- 0: Unselect, 1: Selected
	)

	IF @UserId <> 0
	BEGIN
		INSERT INTO #GridOfExcludedTargetCountry(CountryCode, CountryName, Status)
		SELECT DISTINCT tc.CountryCode, tc.CountryName, 0
		FROM dbo.UserMarket um WITH (NOLOCK)
			INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.MarketID = um.MarketId
		WHERE um.CustId = @UserId

		IF @PageId <> 0 -- Edit Landing Page
		BEGIN
			;WITH CTE_lp AS
			(
				SELECT lp.BlockTargetCountry
				FROM dbo.LandingPage lp WITH (NOLOCK) 
				WHERE lp.PageId = @PageId 
				  AND lp.IsDeleted = 0
			)
			UPDATE gbtc
			SET gbtc.Status = 1
			FROM #GridOfExcludedTargetCountry gbtc
				INNER JOIN CTE_lp n ON ',' + n.BlockTargetCountry + ',' LIKE '%,' + gbtc.CountryCode + ',%'
		END
	END
	ELSE
	BEGIN
		INSERT INTO #GridOfExcludedTargetCountry(CountryCode, CountryName, Status)
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
	FROM #GridOfExcludedTargetCountry
	ORDER BY OrderID ASC

	DROP TABLE #GridOfExcludedTargetCountry
END
GO