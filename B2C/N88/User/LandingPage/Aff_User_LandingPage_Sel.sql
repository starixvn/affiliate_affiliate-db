/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_LandingPage_Sel]
	@TargetCountryCode	VARCHAR(5) = ''
AS

/*
	Created: 20250808@Eddie
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20250808@Eddie: Initialize SP [RedmineID: #227560]
*/

BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT lp.PageId, lp.PageName, lp.PageCode
	FROM dbo.LandingPage lp WITH (NOLOCK)
		OUTER APPLY(
					SELECT t.CountryCode
					FROM(
							SELECT DISTINCT CountryCode
							FROM dbo.TargetCountry WITH (NOLOCK)
							WHERE CountryCode NOT IN (SELECT value FROM STRING_SPLIT(lp.BlockTargetCountry, ','))
						) AS t
					) As oam
	WHERE IsDeleted = 0 AND (oam.CountryCode = @TargetCountryCode OR @TargetCountryCode ='')
	ORDER BY PageId DESC
END
GO