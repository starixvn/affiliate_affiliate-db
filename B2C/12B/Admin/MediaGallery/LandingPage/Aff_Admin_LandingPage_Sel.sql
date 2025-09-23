/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_LandingPage_Sel]
	@PageId SMALLINT = NULL
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
		- 20250721@Eddie: Add new condition [RedmineID: #233219]
		- 20250917@Sophia: Added CanEdit column and add StatusId = 1 condition [RedmineID: #236797]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Default_PageId SMALLINT

	-- Default pagecode
	SELECT @Default_PageId = CONVERT(SMALLINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'LandingPage'

	SELECT lp.PageId, lp.PageName, lp.PageCode, oa.BlockTargetCountry, lp.IsMobile, lp.IsExcluded, lp.DealIds, lp.StatusId, IIF(lp.PageId = @Default_PageId, 1, 0) AS IsDefault -- 'join' is the default
		,CASE 
			WHEN lb.PageCode IS NULL THEN 1
			ELSE 0
		END AS CanEdit
	FROM dbo.LandingPage lp WITH (NOLOCK)
	LEFT JOIN dbo.LandingPage_Builder lb WITH (NOLOCK) ON lb.PageCode = lp.PageCode
	OUTER APPLY (
					SELECT STRING_AGG(t.CountryName, ', ') AS BlockTargetCountry
					FROM(
						SELECT DISTINCT tc.CountryName
						FROM dbo.TargetCountry tc WITH (NOLOCK)
							INNER JOIN STRING_SPLIT(lp.BlockTargetCountry, ',') s ON s.value = tc.CountryCode
						) t
				) AS oa
	WHERE lp.IsDeleted = 0	 
	  AND (@PageId IS NULL OR lp.PageId = @PageId)
	ORDER BY lp.PageId DESC
END
GO
