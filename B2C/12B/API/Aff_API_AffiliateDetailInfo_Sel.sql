/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_API_AffiliateDetailInfo_Sel]
	@DealId				INT = 0
	,@PageIndex			INT = 1
	,@PageSize			INT = 50
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get affiliate information

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20251113@Sally: filter by DealId [RedmineID: #244127]
*/

BEGIN
	SET NOCOUNT ON

	SELECT 
		p.UserName AS ParentAff
		,a.UserName
		,a.AffCode
		,a.CurrencyCode
		,a.RegisteredDate
		,ad.LastLoginDate
		,ad.LastLoginIP
		,ad.Player_Username
		,a.FirstName
		,a.LastName
		,ad.Phone
		,CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status 
		,a.Email
		,ad.Player_CustId
		,a.AffId
		,cg.DealVerifyFlags
		,a.AffCategoryId
	FROM dbo.AffInfo a WITH(NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
		INNER JOIN dbo.CommGroup cg WITH(NOLOCK) ON cg.GroupId = a.GroupId
		LEFT JOIN dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
	WHERE a.Status = 'Approved' --AND a.IsRejected = 0
		AND (ISNULL(@DealId, 0) = 0 OR a.GroupId = @DealId)
	ORDER BY a.AffId ASC
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH FIRST @PageSize ROWS ONLY
END
GO