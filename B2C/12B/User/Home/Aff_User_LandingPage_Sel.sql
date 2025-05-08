/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_LandingPage_Sel]
	@TargetCountryCode	VARCHAR(5) = ''
AS

/*
	Created: 20250417@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: User Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20250417@Lewis: Initialize SP [RedmineID: #223644]
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