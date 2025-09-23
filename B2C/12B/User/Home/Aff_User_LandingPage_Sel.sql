/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_LandingPage_Sel]
	@AffID 				INT = 0
	,@TargetCountryCode	VARCHAR(5) = ''
	,@IsMobile			BIT = 0
AS

/*
	Created: 20250417@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: User Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20250417@Lewis: Initialize SP [RedmineID: #223644]
		- 20250721@Eddie: Add new condition [RedmineID: #233219]
        - 20250918@Sally: Get PageCode Active Status [RedmineID: #236797]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @DealId INT

	SELECT @DealId = GroupId FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffID

	SELECT DISTINCT lp.PageId, lp.PageName, lp.PageCode
	FROM dbo.LandingPage lp WITH (NOLOCK)
		OUTER APPLY(
			SELECT CountryCode
			FROM dbo.Country WITH (NOLOCK)
			WHERE CountryCode NOT IN (SELECT value FROM STRING_SPLIT(lp.BlockTargetCountry, ','))
		) As oam
	WHERE IsDeleted = 0 
        AND lp.StatusId = 1  -- Active Status
	    AND (@TargetCountryCode = '' OR oam.CountryCode = @TargetCountryCode)
	    AND ( @AffID = 0
		 OR lp.IsExcluded = 1 AND lp.DealIds = ''
		 OR lp.IsExcluded = 1 AND ( ',' + lp.DealIds + ',' NOT LIKE ('%,' + CONVERT(VARCHAR(10), @DealId) + ',%' ) )
		 OR lp.IsExcluded = 0 AND lp.DealIds = '0'
		 OR lp.IsExcluded = 0 AND ( ',' + lp.DealIds + ',' LIKE ('%,' + CONVERT(VARCHAR(10), @DealId) + ',%' ) )
	  )
	  AND IsMobile = @IsMobile
	ORDER BY PageId DESC
END
GO