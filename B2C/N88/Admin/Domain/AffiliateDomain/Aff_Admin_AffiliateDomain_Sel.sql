/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Sel]
	@CountryCode VARCHAR(5) = NULL
AS

/*  
	Created: 20191010@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Domain - Affiliate Domain - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20250729@Danny: Add BlockTargetCountry [RedmineID: #227560]
*/

BEGIN
	SET NOCOUNT ON

	SELECT	a.DomainID
			, a.DomainName
			, b.Username AS Creator
			, a.CreateDate
			, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
			, oa.BlockTargetCountry
			, IIF(a.BlockTargetCountry = '', NULL, a.BlockTargetCountry) AS BlockTargetCountryCode
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.Affiliate_User b WITH (NOLOCK) ON a.Creator = b.CustId
		OUTER APPLY (
						SELECT STRING_AGG(t.CountryName, ', ') AS BlockTargetCountry
						FROM(
							SELECT DISTINCT tc.CountryName
							FROM dbo.TargetCountry tc WITH (NOLOCK)
								INNER JOIN STRING_SPLIT(a.BlockTargetCountry, ',') s ON s.value = tc.CountryCode
							) t
					) AS oa
	WHERE a.IsDeleted = 0
		AND  (	
				(@CountryCode IS NOT NULL AND ( CHARINDEX(@CountryCode, a.BlockTargetCountry) = 0 OR CHARINDEX(@CountryCode, a.BlockTargetCountry) IS NULL))
				OR @CountryCode IS NULL
			)
	ORDER BY a.CreateDate DESC, a.DomainName
END
GO