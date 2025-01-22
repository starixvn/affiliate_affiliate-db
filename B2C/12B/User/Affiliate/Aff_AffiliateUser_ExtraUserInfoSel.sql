/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_AffiliateUser_ExtraUserInfoSel]
	@AffId 		INT = 0
	,@AffCode	VARCHAR(20) = ''
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/
BEGIN
	SET NOCOUNT ON

	IF ISNULL(@AffCode, '') <> ''
		SELECT @AffId = AffId FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffCode = @AffCode

    SELECT g.GroupName, 0 AS HasDailyDetail
    FROM CommGroup g WITH(NOLOCK)
		INNER JOIN AffInfo ai WITH(NOLOCK) ON g.GroupId = ai.GroupId
    WHERE ai.AffId = @AffId
END
GO