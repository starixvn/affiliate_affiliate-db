/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Sel]
	@PageId SMALLINT = NULL
AS

/*
	Created: 20181001@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
		- 20191127@Percy: Sort by newest landing page [RedmineID: #118992]
		- 20250729@Danny: Add BlockTargetCountry [RedmineID: #227560]
*/

BEGIN
	SET NOCOUNT ON

	SELECT lp.PageId, lp.PageName, lp.PageCode, oa.BlockTargetCountry
	FROM dbo.LandingPage lp WITH (NOLOCK)
		OUTER APPLY (
					SELECT STRING_AGG(t.CountryName, ', ') AS BlockTargetCountry
					FROM(
						SELECT DISTINCT tc.CountryName
						FROM dbo.TargetCountry tc WITH (NOLOCK)
							INNER JOIN STRING_SPLIT(lp.BlockTargetCountry, ',') s ON s.value = tc.CountryCode
						) t
				) AS oa
	WHERE IsDeleted = 0
		AND (@PageId IS NULL OR PageId = @PageId)
	ORDER BY PageId DESC
END
GO