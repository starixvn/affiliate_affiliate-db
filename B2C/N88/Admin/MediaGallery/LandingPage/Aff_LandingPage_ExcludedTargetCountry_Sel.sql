/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_ExcludedTargetCountry_Sel]
	@PageId SMALLINT = 0
AS
/*  
	Created: 20250729@Danny
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Media Gallery - Landing Page List - Excluded Target Country Popup

	Revisions:
		- 20250729@Danny: Initialize SP [RedmineID: #227560]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #GridOfExcludedTargetCountry
	(
		CountryCode VARCHAR(2)
	   ,CountryName	NVARCHAR(100)
	   ,Status		TINYINT	-- 0: Unselect, 1: Selected
	   ,OrderNo		INT
	)
	INSERT INTO #GridOfExcludedTargetCountry(CountryCode, CountryName, Status, OrderNo)
	SELECT DISTINCT CountryCode, CountryName, 0, OrderNo
	FROM dbo.TargetCountry WITH (NOLOCK)
	WHERE OrderNo IS NOT NULL

	IF @PageId <> 0 -- Edit Landing Page
	BEGIN
		;WITH CTE_lp AS
		(
			SELECT DISTINCT ca.value AS BlockTargetCountry
			FROM dbo.LandingPage lp WITH (NOLOCK)
				CROSS APPLY (SELECT s.value FROM string_split (lp.BlockTargetCountry,',') s) ca
			WHERE lp.PageId = @PageId 
			  AND lp.IsDeleted = 0
		)
		UPDATE gbtc
		SET gbtc.Status = 1
		FROM #GridOfExcludedTargetCountry gbtc
		WHERE EXISTS (SELECT 1 FROM CTE_lp n WHERE gbtc.CountryCode = n.BlockTargetCountry)
	END

	-- TODO: Result
	SELECT CountryCode AS TargetCountryCode, CountryName AS TargetCountryName, Status
		,OrderNo
	FROM #GridOfExcludedTargetCountry
	ORDER BY OrderNo ASC

	DROP TABLE #GridOfExcludedTargetCountry
END
GO